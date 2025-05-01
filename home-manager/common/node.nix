{
  pkgs,
  lib,
  ...
}: let
  nodejs = pkgs.nodejs_22;

  # Standard node packages from nixpkgs
  standardNodePackages = with pkgs.nodePackages; [
    nodejs
    postcss
    postcss-cli
    wrangler
    yarn
  ];

  # Define package metadata separately for clarity
  npmPackages = [
    {
      name = "better-sqlite3";
      version = "11.9.1";
      sha256 = "sha256-zOpKIXPRPzBGfqBgaFHh8oIDAZhHendnm4SYSERUErs=";
      isESM = null; # auto-detect
    }
    {
      name = "@anthropic-ai/claude-code";
      version = "0.2.97";
      sha256 = "sha256-Lzrg+iXg0CZEiI5ONxXhkwv2wo6EOdl1NmjcgPmY7dA=";
      isESM = true;
      # `claude-code` tries to auto-update by default, this disables that functionality.
      # https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview#environment-variables
      wrapperArgs = ''
        --set DISABLE_AUTOUPDATER 1 --set DISABLE_TELEMETRY 1 --set DISABLE_ERROR_REPORTING 1
      '';
      # Add post-install commands to disable auto-updater for claude-code
      postInstallCommands = ''
        claude config set -g autoUpdaterStatus enabled
      '';
    }
    # Add more packages here as needed
    # {
    #   name = "zx";
    #   version = "7.2.3";
    #   sha256 = "sha256-d0FEspPn8M3Bq4UtX/4ZLNTG8D1DTPLnftCY0tf/IFc=";
    #   isESM = null; # auto-detect
    # }
    # {
    #   name = "degit";
    #   version = "2.8.4";
    #   sha256 = "sha256-H3wfSChRYhrzbVp5l2wkYg0gX+nT4N+Ns0oiVE+BbOw=";
    #   isESM = null; # auto-detect
    # }
  ];

  # Helper for parsing package name info
  parsePackageName = name: let
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
    # For Nix derivation name
    pname = lib.replaceStrings ["@" "/"] ["" "-"] name;
  };

  # Function to construct the npm tarball name
  getNpmTarballName = {
    name,
    version,
  }: let
    packageInfo = parsePackageName name;
  in
    if packageInfo.hasScope
    then "${lib.removePrefix "@" packageInfo.scope}-${packageInfo.packageName}-${version}.tgz"
    else "${name}-${version}.tgz";

  # Function to download a single npm package (for a unified environment)
  fetchNpmPackage = {
    name,
    version,
    sha256,
  }: let
    packageInfo = parsePackageName name;

    # The URL to the npm package
    packageUrl =
      if packageInfo.hasScope
      then "https://registry.npmjs.org/${name}/-/${packageInfo.packageName}-${version}.tgz"
      else "https://registry.npmjs.org/${name}/-/${name}-${version}.tgz";
  in
    pkgs.fetchurl {
      name = "${packageInfo.pname}-${version}.tgz";
      url = packageUrl;
      inherit sha256;
    };

  # Create a unified Node environment with all packages
  unifiedNodeEnv = pkgs.stdenv.mkDerivation {
    name = "unified-node-environment";

    # No source, we'll download each package separately
    dontUnpack = true;

    # Dependencies
    buildInputs = [
      nodejs
      pkgs.jq
      pkgs.gnugrep
    ];

    # Include the makeWrapper functionality via the setup hook
    nativeBuildInputs = [pkgs.makeWrapper];

    # Build the unified environment
    buildPhase = let
      # Generate fetchNpmPackage calls for each package
      fetchCommands =
        lib.concatMapStrings (pkg: ''
          echo "Downloading ${pkg.name}@${pkg.version}..."
          mkdir -p $out/lib/node_modules/${pkg.name}
          tar -xzf ${fetchNpmPackage {
            inherit (pkg) name version sha256;
          }} -C $out/lib/node_modules/${pkg.name} --strip-components=1
        '')
        npmPackages;

      # Process each package to set up bin entries and fix module types
      processCommands =
        lib.concatMapStrings (pkg: let
          packageInfo = parsePackageName pkg.name;
          esmFlag =
            if pkg.isESM == null
            then "auto"
            else if pkg.isESM
            then "true"
            else "false";
        in ''
                            echo "Processing ${pkg.name}..."

                            # Set ESM flag
                            IS_ESM="${esmFlag}"

                            # Auto-detect ESM if needed
                            if [ "$IS_ESM" = "auto" ]; then
                              if [ -f $out/lib/node_modules/${pkg.name}/package.json ]; then
                                if grep -q '"type"[[:space:]]*:[[:space:]]*"module"' $out/lib/node_modules/${pkg.name}/package.json; then
                                  echo "ES module detected through package.json type field"
                                  IS_ESM="true"
                                elif find $out/lib/node_modules/${pkg.name} -name "*.mjs" | grep -q .; then
                                  echo "ES module detected through .mjs file extension"
                                  IS_ESM="true"
                                elif grep -q '\.mjs"' $out/lib/node_modules/${pkg.name}/package.json; then
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

                            echo "Module type for ${pkg.name}: $IS_ESM"

                            # If needed, ensure package.json has type: module for ESM packages
                            if [ "$IS_ESM" = "true" ]; then
                              if [ -f $out/lib/node_modules/${pkg.name}/package.json ]; then
                                if ! grep -q '"type"[[:space:]]*:[[:space:]]*"module"' $out/lib/node_modules/${pkg.name}/package.json; then
                                  # Create a temporary file with the desired content
                                  TMP_FILE=$(mktemp)
                                  cat $out/lib/node_modules/${pkg.name}/package.json | ${pkgs.jq}/bin/jq '. + {"type": "module"}' > $TMP_FILE
                                  mv $TMP_FILE $out/lib/node_modules/${pkg.name}/package.json
                                fi
                              fi
                            fi

                            # Extract bin entries from package.json and create symlinks
                            if [ -f $out/lib/node_modules/${pkg.name}/package.json ]; then
                              # Extract bin field from package.json
                              BIN_FIELD=$(${pkgs.jq}/bin/jq -r '.bin // empty' $out/lib/node_modules/${pkg.name}/package.json)

                              if [ ! -z "$BIN_FIELD" ]; then
                                if echo "$BIN_FIELD" | grep -q '{'; then
                                  # It's an object, extract key-value pairs
                                  ${pkgs.jq}/bin/jq -r 'to_entries[] | "\(.key) \(.value)"' <<< "$BIN_FIELD" | while read -r bin_name bin_path; do
                                    BIN_SOURCE="$out/lib/node_modules/${pkg.name}/$bin_path"
                                    BIN_TARGET="$out/bin/$bin_name"

                                    if [ -f "$BIN_SOURCE" ]; then
                                      # Fix shebangs and make executable
                                      sed -i "1s|^#!.*$|#!/usr/bin/env node|" "$BIN_SOURCE"
                                      chmod +x "$BIN_SOURCE"
                                      ln -s "$BIN_SOURCE" "$BIN_TARGET"
                                      echo "Created binary: $bin_name -> $bin_path for ${pkg.name}"

                                      # Create wrapper for ESM if needed
                                      if [ "$IS_ESM" = "true" ]; then
                                        rm "$BIN_TARGET"
                                        cat > "$BIN_TARGET" << EOF
          #!/usr/bin/env bash
          export NODE_OPTIONS="--experimental-modules --experimental-specifier-resolution=node \$${NODE_OPTIONS:+:NODE_OPTIONS}"
          export NODE_PATH="$out/lib/node_modules:\$NODE_PATH"
          exec ${nodejs}/bin/node "$BIN_SOURCE" "\$@"
          EOF
                                        chmod +x "$BIN_TARGET"
                                        echo "Created ESM wrapper for $bin_name"
                                      fi

                                      # Apply additional wrapper if specified
                                      WRAPPER_ARGS=$(${pkgs.jq}/bin/jq -r --arg pkgname "${pkg.name}" '.[] | select(.name == $pkgname) | .wrapperArgs // empty' <<< '${builtins.toJSON npmPackages}')
                                      if [ ! -z "$WRAPPER_ARGS" ]; then
                                        echo "Applying wrapper args for $bin_name: $WRAPPER_ARGS"
                                        # wrapProgram modifies the script in-place, no need for temp files
                                        wrapProgram "$BIN_TARGET" $WRAPPER_ARGS
                                      fi
                                    else
                                      echo "Warning: Binary source doesn't exist: $BIN_SOURCE"
                                    fi
                                  done
                                else
                                  # It's a string, use package name as the binary name
                                  bin_name="${packageInfo.packageName}"
                                  bin_path=$(${pkgs.jq}/bin/jq -r '.bin' $out/lib/node_modules/${pkg.name}/package.json)
                                  BIN_SOURCE="$out/lib/node_modules/${pkg.name}/$bin_path"
                                  BIN_TARGET="$out/bin/$bin_name"

                                  if [ -f "$BIN_SOURCE" ]; then
                                    # Fix shebangs and make executable
                                    sed -i "1s|^#!.*$|#!/usr/bin/env node|" "$BIN_SOURCE"
                                    chmod +x "$BIN_SOURCE"
                                    ln -s "$BIN_SOURCE" "$BIN_TARGET"
                                    echo "Created binary: $bin_name -> $bin_path for ${pkg.name}"

                                    # Create wrapper for ESM if needed
                                    if [ "$IS_ESM" = "true" ]; then
                                      rm "$BIN_TARGET"
                                      cat > "$BIN_TARGET" << EOF
          #!/usr/bin/env bash
          export NODE_OPTIONS="--experimental-modules --experimental-specifier-resolution=node \$${NODE_OPTIONS:+:NODE_OPTIONS}"
          export NODE_PATH="$out/lib/node_modules:\$NODE_PATH"
          exec ${nodejs}/bin/node "$BIN_SOURCE" "\$@"
          EOF
                                      chmod +x "$BIN_TARGET"
                                      echo "Created ESM wrapper for $bin_name"
                                    fi

                                    # Apply additional wrapper if specified
                                    WRAPPER_ARGS=$(${pkgs.jq}/bin/jq -r --arg pkgname "${pkg.name}" '.[] | select(.name == $pkgname) | .wrapperArgs // empty' <<< '${builtins.toJSON npmPackages}')
                                    if [ ! -z "$WRAPPER_ARGS" ]; then
                                      echo "Applying wrapper args for $bin_name: $WRAPPER_ARGS"
                                      # wrapProgram modifies the script in-place, no need for temp files
                                      wrapProgram "$BIN_TARGET" $WRAPPER_ARGS
                                    fi
                                  else
                                    echo "Warning: Binary source doesn't exist: $BIN_SOURCE"
                                  fi
                                fi
                              fi
                            fi
        '')
        npmPackages;
    in ''
            mkdir -p $out/bin $out/lib/node_modules

            # Download and extract all packages
            ${fetchCommands}

            # Process each package (bin entries, etc)
            ${processCommands}

            # Create a package.json for the unified environment
            mkdir -p $out/etc
            cat > $out/etc/unified-env-metadata.json << EOF
      {
        "name": "unified-node-environment",
        "version": "1.0.0",
        "description": "Unified Node environment with all packages",
        "dependencies": {
          ${lib.concatMapStringsSep ",\n    " (pkg: "\"${pkg.name}\": \"${pkg.version}\"") npmPackages}
        }
      }
      EOF
    '';

    # Nothing to install, everything is done in buildPhase
    dontInstall = true;

    # Skip standard fixup phases
    dontFixup = true;

    meta = with lib; {
      description = "Unified Node environment with all packages";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };

  # All packages together
  allPackages = standardNodePackages ++ [unifiedNodeEnv];
in {
  # Return an attrset with both packages and metadata
  packages = allPackages;

  # Add Home Manager activation script to run node post-install commands
  # Only add the activation script if there are actually post-install commands to run
  home.activation.nodePostInstall = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Running Node.js package post-installation tasks..."
    ${lib.concatMapStrings (
        pkg:
          if pkg ? postInstallCommands && pkg.postInstallCommands != ""
          then ''
            echo "Running post-install configuration for ${pkg.name}..."
            ${pkg.postInstallCommands}
          ''
          else ""
      )
      npmPackages}
  '';
}
