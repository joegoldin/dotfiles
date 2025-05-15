{
  pkgs,
  lib,
  nodejs_22,
  unstable,
  config,
  ...
}: let
  # Define package metadata separately for clarity
  npmPackages = [
    # Add packages here as needed. Make sure dependencies are satisfied.
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

  # List of packages to install directly via npm at home-manager activation time
  # These will be installed to ~/.npm-global using npm install -g
  directNpmPackages = [
    {
      name = "better-sqlite3";
    }
    {
      name = "@anthropic-ai/claude-code";
      # specify env variables to set for this package
      env = {
        DISABLE_AUTOUPDATER = "1";
        DISABLE_TELEMETRY = "1";
        DISABLE_ERROR_REPORTING = "1";
      };
      postInstall = ''
        claude config set -g autoUpdaterStatus disabled
      '';
    }
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

  # Create a unified Node environment to be installed at activation time
  unifiedNodeEnv = pkgs.stdenv.mkDerivation {
    name = "unified-node-environment";

    # No source, we'll download each package separately
    dontUnpack = true;

    # Dependencies
    buildInputs = [
      nodejs_22
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
                        mkdir -p $out/bin
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
          exec ${nodejs_22}/bin/node "$BIN_SOURCE" "\$@"
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
          exec ${nodejs_22}/bin/node "$BIN_SOURCE" "\$@"
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

  # Activation script to install npm packages to ~/.npm-global
  npmActivationScript = ''
        echo "Installing Node.js packages from Nix store to ~/.npm-global..."

        # Create npm global directories if they don't exist
        mkdir -p ~/.npm-global/bin ~/.npm-global/lib/node_modules

        # Get the path to this package in the Home Manager profile
        NODE_ENV_PATH="${config.home.profileDirectory}"

        # Copy all modules to the npm global directory from Home Manager profile
        if [ -d "$NODE_ENV_PATH/lib/node_modules" ]; then
          echo "Copying Node modules from $NODE_ENV_PATH/lib/node_modules to ~/.npm-global/lib/node_modules"
          cp -R "$NODE_ENV_PATH/lib/node_modules/"* ~/.npm-global/lib/node_modules/
        fi

        # Link all binaries to the npm global bin directory
        for bin in "${nodejs_22}/bin/"*; do
          if [ -f "$bin" ] && [ -x "$bin" ]; then
            binname=$(basename "$bin")
            echo "Linking binary: $binname"
            ln -sf "$bin" ~/.npm-global/bin/$binname
          fi
        done

        # Create a metadata file
        mkdir -p ~/.npm-global/etc
        cat > ~/.npm-global/etc/unified-env-metadata.json << EOJ
    {
      "name": "unified-node-environment",
      "version": "1.0.0",
      "description": "Unified Node environment with all packages",
      "dependencies": {
        ${lib.concatMapStringsSep ",\n    " (pkg: "\"${pkg.name}\": \"${pkg.version}\"") npmPackages}
      }
    }
    EOJ
  '';

  # Generate script for direct npm package installs (completely separate from npmPackages)
  directNpmInstallScript = let
    # Create install commands for each package
    installCommands =
      lib.concatMapStringsSep "\n" (pkg: let
        # Package name and version
        packageSpec =
          if pkg ? version && pkg.version != null
          then "${pkg.name}@${pkg.version}"
          else pkg.name;

        # Environment variables for this package
        envVars =
          if pkg ? env
          then
            lib.concatStringsSep " " (lib.mapAttrsToList
              (name: value: "${name}=\"${value}\"")
              pkg.env)
          else "";

        # Post-install commands for this package
        postInstall =
          if pkg ? postInstall
          then pkg.postInstall
          else "";
      in ''
        echo "Installing ${packageSpec} using npm install..."
        # Ensure node is in PATH
        ${
          if envVars != ""
          then "export ${envVars}"
          else ""
        }
        ${nodejs_22}/bin/npm install -g ${packageSpec} --prefix ~/.npm-global
        ${postInstall}
      '')
      directNpmPackages;
  in ''
    echo "Installing npm packages directly using npm..."
    # Create npm global directory if it doesn't exist
    mkdir -p ~/.npm-global/bin ~/.npm-global/lib/node_modules

    # Make sure node is available in PATH
    export PATH="${nodejs_22}/bin:$PATH"

    # Install packages directly via npm
    ${installCommands}
  '';

  # Define yarn2nix packages to install from GitHub
  yarnFromGitHubPackages = [
    # {
    #   name = "extraterm";
    #   owner = "sedwards2009";
    #   repo = "extraterm";
    #   rev = "v0.81.0";
    #   sha256 = "sha256-H5aP7inGaUXD1SUyijsaaR5qki6yIzaq71MYPaoNSxo=";
    #   yarnHash = "sha256-COQKq1MIr/tQBxLQKwE215Xm8wih0W2pjVuxYQYDrvo=";
    #   missingHashesHash = "sha256-v46ENvN0pT+vcQiSnH1bquSMzpvu9WmnNrGeNmqA2/Y=";
    # }
  ];

  # Function to build a yarn package from GitHub
  buildYarnPackageFromGitHub = {
    name,
    owner,
    repo,
    rev,
    sha256,
    yarnHash,
    missingHashesHash,
    buildPhase ? "",
    installPhase ? "",
    extraArgs ? {},
  }: let
    source = pkgs.stdenv.mkDerivation {
      name = "${name}-source-${rev}";
      src = pkgs.fetchFromGitHub {
        inherit owner repo rev sha256;
      };

      # buildPhase = ''
      # '';

      installPhase = ''
        cp -r . $out
      '';
    };

    yarnLockFile = "${source}/yarn.lock";
    packageJSON = "${source}/package.json";

    # Generate missing-hashes.json for this package
    missingHashesFile = pkgs.stdenv.mkDerivation {
      name = "missing-hashes-${name}-${rev}-243}";

      src = source;

      # Reference the yarn lock file
      inherit source yarnLockFile;

      buildInputs = with pkgs.unstable; [nodejs_22 yarn-berry_3 yarn-berry_3.yarn-berry-fetcher];

      nativeBuildInputs = with pkgs.unstable; [nodejs_22 yarn-berry_3 yarn-berry_3.yarn-berry-fetcher];

      buildPhase = ''
        yarn-berry-fetcher missing-hashes $yarnLockFile > missing-hashes.json
      '';

      installPhase = ''
        mkdir -p $out
        cp missing-hashes.json $out
      '';

      # Fixed-output derivation settings
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
      outputHash = missingHashesHash;
    };

    missingHashesFilePath = "${missingHashesFile}/missing-hashes.json";

    offlineCache = pkgs.unstable.yarn-berry_3.fetchYarnBerryDeps {
      yarnLock = yarnLockFile;
      hash = yarnHash;
      missingHashes = missingHashesFilePath;
    };
  in
    pkgs.mkYarnPackage (extraArgs
      // {
        pname = name;
        version = rev;
        src = source;

        nativeBuildInputs = [
          nodejs_22
          pkgs.unstable.yarn-berry_3.yarnBerryConfigHook
        ];

        inherit offlineCache;
        missingHashes = missingHashesFilePath;
        packageJSON = packageJSON;

        # Use custom build phase if provided
        buildPhase =
          if buildPhase != ""
          then buildPhase
          else null;

        # Use custom install phase if provided
        installPhase =
          if installPhase != ""
          then installPhase
          else null;
      });

  # Build all yarn packages from GitHub
  yarnFromGitHubDerivations = lib.listToAttrs (map (
      pkg:
        lib.nameValuePair pkg.name (buildYarnPackageFromGitHub pkg)
    )
    yarnFromGitHubPackages);
in {
  # Export all systems - the caller can choose which to use
  inherit
    npmPackages
    unifiedNodeEnv
    npmActivationScript
    directNpmPackages
    directNpmInstallScript
    yarnFromGitHubPackages
    yarnFromGitHubDerivations
    buildYarnPackageFromGitHub
    ;
}
