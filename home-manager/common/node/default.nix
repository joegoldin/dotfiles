{
  pkgs,
  lib,
  unstable,
  config,
  ...
}: let
  nodejs_22 = unstable.nodejs_22;

  # Standard node packages from nixpkgs
  standardNodePackages = [
    unstable.marp-cli
    unstable.nodePackages.fx
    unstable.nodejs_22
    unstable.nodePackages.postcss
    unstable.wrangler
    unstable.yarn-berry_3
  ];

  # Import custom packages from separate file
  customNodePackages = import ./custom-node-packages.nix {
    inherit pkgs lib nodejs_22 unstable config;
  };

  # Build yarn packages from GitHub
  yarnFromGitHubPackages = builtins.attrValues customNodePackages.yarnFromGitHubDerivations;

  # All packages together - include both standard packages and our custom environment
  allPackages = standardNodePackages ++ [customNodePackages.unifiedNodeEnv] ++ yarnFromGitHubPackages;
in {
  # Return an attrset with both packages and metadata
  packages = allPackages;

  # This runs before packages are installed to set up npm's global prefix
  nodePreInstall = lib.hm.dag.entryBefore ["installPackages"] ''
    # Put grc on path via nix pkg
    export PATH="$PATH:${pkgs.grc}/bin"

    # Create npm global directory if it doesn't exist
    mkdir -p ~/.npm-global

    # Set npm global prefix
    ${nodejs_22}/bin/npm set prefix ~/.npm-global

    # Ensure npm will always use this prefix for global installs
    ${nodejs_22}/bin/npm config set global true

    # Add npm global bin to PATH
    export PATH="$HOME/.npm-global/bin:$PATH"
    ${pkgs.fish}/bin/fish -c "set -Ux PATH $HOME/.npm-global/bin:$PATH"

    # Set NODE_PATH to include Nix-installed node modules
    export NODE_PATH="${config.home.profileDirectory}/lib/node_modules:$HOME/.npm-global/lib/node_modules"
    ${pkgs.fish}/bin/fish -c "set -Ux NODE_PATH \"${config.home.profileDirectory}/lib/node_modules:$HOME/.npm-global/lib/node_modules\""

    # Export Node package environment variables
    ${lib.concatStringsSep "\n" (lib.concatMap (
        pkg:
          if pkg ? env
          then
            lib.mapAttrsToList (
              name: value: ''                echo "Exporting ${name}=${value} for ${pkg.name}..."
                            export ${name}="${value}"
                            ${pkgs.fish}/bin/fish -c "set -Ux ${name} ${value}"''
            )
            pkg.env
          else []
      )
      customNodePackages.directNpmPackages)}
  '';

  # This runs after packages are installed - we'll use two separate systems:
  # 1. Nix packages via unifiedNodeEnv - available in HM profile
  # 2. Direct npm installs to ~/.npm-global
  nodeSetupGlobal = lib.hm.dag.entryAfter ["installPackages"] ''
    # Install additional packages directly via npm to ~/.npm-global
    ${customNodePackages.directNpmInstallScript}
  '';

  # This runs after modules are installed to execute any package-specific commands
  nodePostInstall = lib.hm.dag.entryAfter ["nodeSetupGlobal"] ''
    echo "Running Node.js package post-installation tasks..."

    # Run post-install commands for the packages from npmPackages
    ${lib.concatStringsSep "\n" (lib.filter (cmd: cmd != "") (map (
        pkg:
          if pkg ? postInstall && pkg.postInstall != ""
          then ''
            echo "Running post-install configuration for ${pkg.name}..."
            run ${pkg.postInstall}
          ''
          else ""
      )
      customNodePackages.npmPackages))}

    # Run post-install commands for yarn GitHub packages if they have any
    ${lib.concatStringsSep "\n" (lib.filter (cmd: cmd != "") (map (
        pkg:
          if pkg ? postInstall && pkg.postInstall != ""
          then ''
            echo "Running post-install configuration for GitHub yarn package ${pkg.name}..."
            run ${pkg.postInstall}
          ''
          else ""
      )
      customNodePackages.yarnFromGitHubPackages))}
  '';
}
