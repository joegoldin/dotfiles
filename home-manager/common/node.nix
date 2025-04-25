{
  pkgs,
  lib,
  ...
}: let
  nodejs = pkgs.nodejs_20;

  # Helper function to build any npm package with automatic ES module detection
  buildNpmPackage = {
    name,
    version,
    sha256,
    isESM ? null,
  }: let
    # Parse the package name to handle scoped packages
    packageInfo = let
      hasScope = lib.hasPrefix "@" name;
      scope =
        if hasScope
        then lib.elemAt (lib.splitString "/" name) 0
        else null;
      packageName =
        if hasScope
        then lib.elemAt (lib.splitString "/" name) 1
        else name;
      packagePath =
        if hasScope
        then name
        else name;
    in {
      inherit hasScope scope packageName packagePath;
      # For the tarball name, scoped packages use different format:
      # @org/pkg -> org-pkg-version.tgz
      tarballName =
        if hasScope
        then "${lib.removePrefix "@" scope}-${packageName}-${version}.tgz"
        else "${name}-${version}.tgz";
    };

    # The URL to the npm package
    packageUrl =
      if packageInfo.hasScope
      then "https://registry.npmjs.org/${name}/-/${packageInfo.packageName}-${version}.tgz"
      else "https://registry.npmjs.org/${name}/-/${name}-${version}.tgz";

    # Define shebang replacements for both ES modules and regular modules
    # Use nodejs from path to avoid hanging issues
    esmShebang = "#!/usr/bin/env node";
    regularShebang = "#!/usr/bin/env node";

    # If isESM is explicitly set, use it; otherwise we'll detect it during the build
    knownEsm = isESM != null;
  in
    pkgs.stdenv.mkDerivation {
      pname = lib.replaceStrings ["@" "/"] ["" "-"] name;
      inherit version;

      # Download the package
      src = pkgs.fetchurl {
        url = packageUrl;
        inherit sha256;
      };

      # Dependencies
      buildInputs = [
        nodejs
        pkgs.jq
        pkgs.gnugrep
      ];

      # Create proper directories and extract the tarball
      unpackPhase = ''
        mkdir -p $out/lib/node_modules/${packageInfo.packagePath}
        tar -xzf $src -C $out/lib/node_modules/${packageInfo.packagePath} --strip-components=1
      '';

      # No build phase required
      dontBuild = true;

      # Install with proper module detection
      installPhase = ''
                mkdir -p $out/bin

                # Determine if this is an ES module (if not explicitly specified)
                IS_ESM=${
          if isESM == null
          then "auto"
          else
            (
              if isESM
              then "true"
              else "false"
            )
        }

                if [ "$IS_ESM" = "auto" ]; then
                  # Check if package.json has "type": "module"
                  if [ -f $out/lib/node_modules/${packageInfo.packagePath}/package.json ]; then
                    if grep -q '"type"[[:space:]]*:[[:space:]]*"module"' $out/lib/node_modules/${packageInfo.packagePath}/package.json; then
                      echo "ES module detected through package.json type field"
                      IS_ESM="true"
                    # Check if any .mjs files exist
                    elif find $out/lib/node_modules/${packageInfo.packagePath} -name "*.mjs" | grep -q .; then
                      echo "ES module detected through .mjs file extension"
                      IS_ESM="true"
                    # Look for bin entry with .mjs extension in package.json
                    elif [ -f $out/lib/node_modules/${packageInfo.packagePath}/package.json ] && grep -q '\.mjs"' $out/lib/node_modules/${packageInfo.packagePath}/package.json; then
                      echo "ES module detected through .mjs reference in package.json"
                      IS_ESM="true"
                    else
                      echo "No ES module indicators found, assuming CommonJS"
                      IS_ESM="false"
                    fi
                  else
                    echo "No package.json found, assuming CommonJS"
                    IS_ESM="false"
                  fi
                fi

                echo "Module type: $IS_ESM"

                # If needed, ensure package.json has type: module
                if [ "$IS_ESM" = "true" ]; then
                  if [ -f $out/lib/node_modules/${packageInfo.packagePath}/package.json ]; then
                    # Only add type: module if not already there
                    if ! grep -q '"type"[[:space:]]*:[[:space:]]*"module"' $out/lib/node_modules/${packageInfo.packagePath}/package.json; then
                      # Create a temporary file with the desired content
                      TMP_FILE=$(mktemp)
                      cat $out/lib/node_modules/${packageInfo.packagePath}/package.json | ${pkgs.jq}/bin/jq '. + {"type": "module"}' > $TMP_FILE
                      mv $TMP_FILE $out/lib/node_modules/${packageInfo.packagePath}/package.json
                    fi
                  fi
                fi

                # Extract bin entries from package.json and create symlinks
                if [ -f $out/lib/node_modules/${packageInfo.packagePath}/package.json ]; then
                  # Extract bin field from package.json
                  BIN_FIELD=$(${pkgs.jq}/bin/jq -r '.bin // empty' $out/lib/node_modules/${packageInfo.packagePath}/package.json)

                  if [ ! -z "$BIN_FIELD" ]; then
                    if echo "$BIN_FIELD" | grep -q '{'; then
                      # It's an object, extract key-value pairs
                      ${pkgs.jq}/bin/jq -r 'to_entries[] | "\(.key) \(.value)"' <<< "$BIN_FIELD" | while read -r bin_name bin_path; do
                        BIN_SOURCE="$out/lib/node_modules/${packageInfo.packagePath}/$bin_path"
                        BIN_TARGET="$out/bin/$bin_name"

                        if [ -f "$BIN_SOURCE" ]; then
                          # Fix shebangs and make executable
                          sed -i "1s|^#!.*$|${
          if isESM == true || "$IS_ESM" == "true"
          then esmShebang
          else regularShebang
        }|" "$BIN_SOURCE"
                          chmod +x "$BIN_SOURCE"
                          ln -s "$BIN_SOURCE" "$BIN_TARGET"
                          echo "Created binary: $bin_name -> $bin_path"
                        else
                          echo "Warning: Binary source doesn't exist: $BIN_SOURCE"
                        fi
                      done
                    else
                      # It's a string, use package name as the binary name
                      bin_name="${packageInfo.packageName}"
                      bin_path=$(${pkgs.jq}/bin/jq -r '.bin' $out/lib/node_modules/${packageInfo.packagePath}/package.json)
                      BIN_SOURCE="$out/lib/node_modules/${packageInfo.packagePath}/$bin_path"
                      BIN_TARGET="$out/bin/$bin_name"

                      if [ -f "$BIN_SOURCE" ]; then
                        # Fix shebangs and make executable
                        sed -i "1s|^#!.*$|${
          if isESM == true || "$IS_ESM" == "true"
          then esmShebang
          else regularShebang
        }|" "$BIN_SOURCE"
                        chmod +x "$BIN_SOURCE"
                        ln -s "$BIN_SOURCE" "$BIN_TARGET"
                        echo "Created binary: $bin_name -> $bin_path"
                      else
                        echo "Warning: Binary source doesn't exist: $BIN_SOURCE"
                      fi
                    fi
                  fi
                fi

                # Create a wrapper script for each binary that sets NODE_OPTIONS
                # This ensures ES modules work properly without modifying shebangs
                if [ "$IS_ESM" = "true" ]; then
                  for bin_file in $out/bin/*; do
                    if [ -L "$bin_file" ]; then
                      bin_name=$(basename "$bin_file")
                      target=$(readlink "$bin_file")

                      # Create a new wrapper script
                      rm "$bin_file"
                      cat > "$bin_file" << EOF
        #!/usr/bin/env bash
        export NODE_OPTIONS="--experimental-modules --experimental-specifier-resolution=node \$${NODE_OPTIONS:+:NODE_OPTIONS}"
        exec ${nodejs}/bin/node "$target" "\$@"
        EOF
                      chmod +x "$bin_file"
                      echo "Created ES module wrapper for $bin_name"
                    fi
                  done
                fi
      '';

      # Skip standard fixup phases
      dontFixup = true;

      meta = with lib; {
        description = "Nix-packaged npm package: ${name}";
        homepage = "https://www.npmjs.com/package/${name}";
        license = licenses.mit; # Assumes MIT license, change if needed
        platforms = platforms.all;
      };
    };

  # Standard node packages from nixpkgs
  nixNodePackages = with pkgs.nodePackages; [
    nodejs
    postcss
    postcss-cli
    wrangler
    yarn
  ];

  # Custom npm packages with specific versions and hashes
  customNpmPackages = [
    # Claude Code - with automatic ES module detection
    (buildNpmPackage {
      name = "@anthropic-ai/claude-code";
      version = "0.2.9";
      sha256 = "sha256-/WBysiuds6ZwwSSUFDr+sGHgRYCyFhH6bEai+XxHsYw=";
      isESM = true; # Explicitly set for claude-code since we know it's an ES module
    })

    # Example of additional packages
    # (buildNpmPackage {
    #   name = "zx";
    #   version = "7.2.3";
    #   sha256 = "sha256-d0FEspPn8M3Bq4UtX/4ZLNTG8D1DTPLnftCY0tf/IFc=";
    #   # isESM automatically detected
    # })
    #
    # (buildNpmPackage {
    #   name = "degit";
    #   version = "2.8.4";
    #   sha256 = "sha256-H3wfSChRYhrzbVp5l2wkYg0gX+nT4N+Ns0oiVE+BbOw=";
    #   # isESM automatically detected
    # })
  ];
in
  nixNodePackages ++ customNpmPackages
