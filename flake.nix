{
  description = "Joe Goldin Nix Config";

  inputs = {
    # assets (fonts, etc.)
    dotfiles-assets = {
      url = "git+file:assets";
      flake = false;
    };
    # secrets (domains, encrypted age files, etc.)
    dotfiles-secrets = {
      url = "git+file:secrets";
      flake = false;
    };
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";
    # darwin
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # wsl
    nixos-wsl.url = "github:nix-community/NixOS-WSL/release-25.11";
    # flake-utils
    flake-utils.url = "github:numtide/flake-utils?ref=v1.0.0";
    # systems
    systems.url = "github:nix-systems/default?rev=da67096a3b9bf56a91d16901293e51ba5b49a27e";
    # devenv
    devenv.url = "github:cachix/devenv?ref=v1.11.2";
    # nixpkgs-python
    nixpkgs-python.url = "github:cachix/nixpkgs-python?rev=04b27dbad2e004cb237db202f21154eea3c4f89f";
    # pre-commit-hooks
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix?rev=b68b780b69702a090c8bb1b973bab13756cc7a27";
    # brew-nix
    brew-nix = {
      url = "github:BatteredBunny/brew-nix?rev=b314426c17667bcebd73ed7e57ecae2bac9755cf";
      inputs.brew-api.follows = "brew-api";
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    # nix-homebrew
    nix-homebrew.url = "github:zhaofengli/nix-homebrew?rev=6a8ab60bfd66154feeaa1021fc3b32684814a62a";
    # Homebrew taps
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-services = {
      url = "github:homebrew/homebrew-services";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    # Additional taps
    homebrew-argoproj = {
      url = "github:argoproj/homebrew-tap";
      flake = false;
    };
    homebrew-assemblyai = {
      url = "github:assemblyai/homebrew-assemblyai";
      flake = false;
    };
    homebrew-k9s = {
      url = "github:derailed/homebrew-k9s";
      flake = false;
    };
    homebrew-ibigio = {
      url = "github:ibigio/homebrew-tap";
      flake = false;
    };
    homebrew-vd = {
      url = "github:saulpw/homebrew-vd";
      flake = false;
    };
    homebrew-ocr = {
      url = "github:schappim/homebrew-ocr";
      flake = false;
    };
    homebrew-skip = {
      url = "github:skiptools/homebrew-skip";
      flake = false;
    };
    homebrew-txn2 = {
      url = "github:txn2/homebrew-tap";
      flake = false;
    };
    homebrew-versent = {
      url = "github:versent/homebrew-taps";
      flake = false;
    };
    homebrew-blacktop = {
      url = "github:blacktop/homebrew-tap";
      flake = false;
    };
    homebrew-cirruslabs = {
      url = "github:cirruslabs/homebrew-cli";
      flake = false;
    };
    homebrew-neilberkman = {
      url = "github:neilberkman/homebrew-clippy";
      flake = false;
    };
    #disko
    disko = {
      url = "github:nix-community/disko?ref=v1.13.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # agenix
    agenix = {
      url = "github:ryantm/agenix?rev=fcdea223397448d35d9b31f798479227e80183f6";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # plasma-manager for KDE configuration
    plasma-manager = {
      url = "github:nix-community/plasma-manager?rev=51816be33a1ff0d4b22427de83222d5bfa96d30e";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    # affinity apps
    affinity-nix = {
      url = "github:mrshmllow/affinity-nix?rev=0c110a15fb5605490f7de451073db1c775745fee";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # for mkWindowsApp
    erosanix = {
      url = "github:emmanuelrosa/erosanix?rev=ce9b9a671ace6e1c446bcfd3e24a17a3674d04ca";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # for secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # LLM agent tools (claude-code, codex, gemini-cli)
    llm-agents.url = "github:numtide/llm-agents.nix?rev=398181e94b91ad081fad17d9b5eab140411d6a29";
    # superpowers (Claude Code skills)
    superpowers = {
      url = "github:obra/superpowers?ref=v4.0.3";
      flake = false;
    };
    # claude-nix (Claude Code configuration library)
    claude-nix = {
      url = "github:joegoldin/claude-nix?rev=337e48e08076a01c12a00290a318955e5e8bd6d2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # mcps.nix (declarative MCP server configuration)
    mcps = {
      url = "github:roman/mcps.nix?rev=25acc4f20f5928a379e80341c788d80af46474b1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    # pelican panel (game server management)
    pelican = {
      url = "github:joegoldin/nix-pelican?rev=900716d90d01a27666d65c9c112acde4c725ae9f";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nix-rosetta-builder for fast x86_64-linux builds on Apple Silicon
    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder?rev=ebb7162a975074fb570a2c3ac02bc543ff2e9df4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nix-flatpak for declarative flatpak management
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
    experimental-features = "nix-command flakes";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-wsl,
      nix-darwin,
      devenv,
      flake-utils,
      systems,
      nixpkgs-python,
      pre-commit-hooks,
      brew-nix,
      brew-api,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      homebrew-services,
      homebrew-bundle,
      homebrew-argoproj,
      homebrew-assemblyai,
      homebrew-k9s,
      homebrew-ibigio,
      homebrew-vd,
      homebrew-ocr,
      homebrew-skip,
      homebrew-txn2,
      homebrew-versent,
      homebrew-blacktop,
      homebrew-cirruslabs,
      homebrew-neilberkman,
      disko,
      agenix,
      plasma-manager,
      affinity-nix,
      erosanix,
      lanzaboote,
      llm-agents,
      dotfiles-assets,
      dotfiles-secrets,
      superpowers,
      claude-nix,
      mcps,
      pelican,
      nix-rosetta-builder,
      nix-flatpak,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      username = "joe";
      useremail = "joe@joegold.in";
      hostname = "${username}-nix";
      homeDirectory = nixpkgs.lib.mkForce "/home/${username}";
      stateVersion = "24.11";
      commonSpecialArgs = inputs // {
        inherit
          inputs
          outputs
          useremail
          stateVersion
          username
          hostname
          homeDirectory
          dotfiles-assets
          dotfiles-secrets
          ;
      };
      eachSystem = nixpkgs.lib.genAttrs (import systems);
      basePackages = eachSystem (
        system: import ./hosts/common/system/pkgs nixpkgs.legacyPackages.${system}
      );
      additionalPackages = eachSystem (system: {
        # devenv-up = self.devShells.${system}.default.config.procfileScript;
      });
      inherit (erosanix) mkWindowsApp;
    in
    {
      # Your custom packages
      # Accessible through 'nix build', 'nix shell', etc
      packages = eachSystem (system: basePackages.${system} // additionalPackages.${system});
      formatter = eachSystem (system: nixpkgs.legacyPackages.${system}.alejandra);

      # Your custom packages and modifications, exported as overlays
      overlays = import ./hosts/common/system/overlays { inherit inputs; };

      checks = eachSystem (system: {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            check-yaml.enable = true;
            end-of-file-fixer.enable = true;
            gitleaks = {
              enable = true;
              name = "gitleaks";
              entry = "${nixpkgs.legacyPackages.${system}.gitleaks}/bin/gitleaks detect --source . -v";
            };
          };
        };
      });

      devShells = eachSystem (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
        };
      });

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#joe-wsl'
      nixosConfigurations = {
        joe-wsl = nixpkgs.lib.nixosSystem {
          specialArgs = commonSpecialArgs // {
            hostname = "joe-wsl";
          };
          modules = [
            nixos-wsl.nixosModules.default
            # > Our main nixos configuration <
            ./hosts/wsl
            home-manager.nixosModules.home-manager
            (
              { specialArgs, ... }:
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.extraSpecialArgs = specialArgs;
                home-manager.backupFileExtension = "backup"; # enable moving existing files
                home-manager.users.${specialArgs.username} = import ./hosts/wsl/home-manager.nix;
              }
            )
            agenix.nixosModules.default
          ];
        };

        oracle-cloud-bastion = nixpkgs.lib.nixosSystem {
          specialArgs = commonSpecialArgs // {
            hostname = "bastion";
          };
          modules = [
            disko.nixosModules.disko
            pelican.nixosModules.default
            { nixpkgs.overlays = [ pelican.overlays.default ]; }
            # > Our main nixos configuration <
            ./hosts/oracle-cloud
            home-manager.nixosModules.home-manager
            (
              { specialArgs, ... }:
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.extraSpecialArgs = specialArgs;
                home-manager.backupFileExtension = "backup"; # enable moving existing files
                home-manager.users.${specialArgs.username} = import ./hosts/oracle-cloud/home-manager.nix;
              }
            )
            agenix.nixosModules.default
            (
              { specialArgs, ... }:
              {
                age.secrets.cf = {
                  file = "${dotfiles-secrets}/cf.json.age";
                  mode = "655";
                  owner = specialArgs.username;
                  group = "users";
                };
                age.identityPaths = [ "/home/${specialArgs.username}/.ssh/id_rsa" ];
              }
            )
          ];
        };

        racknerd-cloud-agent = nixpkgs.lib.nixosSystem {
          specialArgs = commonSpecialArgs // {
            hostname = "racknerd-cloud-agent";
          };
          modules = [
            disko.nixosModules.disko
            # > Our main nixos configuration <
            ./hosts/racknerd-cloud
            home-manager.nixosModules.home-manager
            (
              { specialArgs, ... }:
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.extraSpecialArgs = specialArgs;
                home-manager.backupFileExtension = "backup"; # enable moving existing files
                home-manager.users.${specialArgs.username} = import ./hosts/racknerd-cloud/home-manager.nix;
              }
            )
            agenix.nixosModules.default
            (
              { specialArgs, ... }:
              {
                age.secrets.happy-secrets = {
                  file = "${dotfiles-secrets}/happy-secrets.env.age";
                  mode = "400";
                  owner = "root";
                  group = "root";
                };
                age.identityPaths = [ "/home/${specialArgs.username}/.ssh/id_rsa" ];
              }
            )
          ];
        };

        # Desktop NixOS configuration
        joe-desktop = nixpkgs.lib.nixosSystem {
          specialArgs = commonSpecialArgs // {
            hostname = "joe-desktop";
            inherit inputs mkWindowsApp;
          };
          modules = [
            # > Our main nixos configuration <
            ./hosts/nixos
            home-manager.nixosModules.home-manager
            (
              { specialArgs, ... }:
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.extraSpecialArgs = specialArgs;
                home-manager.backupFileExtension = "backup"; # enable moving existing files
                home-manager.sharedModules = [
                  plasma-manager.homeModules.plasma-manager
                ];
                home-manager.users.${specialArgs.username} = import ./hosts/nixos/home-manager.nix;
              }
            )
            nix-flatpak.nixosModules.nix-flatpak
            agenix.nixosModules.default
            erosanix.nixosModules.mkwindowsapp-gc
            lanzaboote.nixosModules.lanzaboote
          ];
        };
      };

      # Darwin/macOS configuration entrypoint
      # Available through 'darwin-rebuild --flake .#Joes-MacBook-Pro'
      darwinConfigurations = {
        Joes-MacBook-Pro = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = commonSpecialArgs // {
            username = "joe";
            hostname = "Joes-MacBook-Pro";
            homeDirectory = nixpkgs.lib.mkForce "/Users/joe";
          };
          modules = [
            # > Our main darwin configuration <
            ./hosts/darwin
            nix-homebrew.darwinModules.nix-homebrew
            # Rosetta-based Linux builder for fast x86_64-linux builds on Apple Silicon
            nix-rosetta-builder.darwinModules.default
            home-manager.darwinModules.home-manager
            (
              { specialArgs, ... }:
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.extraSpecialArgs = specialArgs;
                home-manager.backupFileExtension = "backup"; # enable moving existing files
                home-manager.users.joe.imports = [
                  ./hosts/darwin/home-manager.nix
                ];
              }
            )
            agenix.darwinModules.default
            {
              # Standard linux-builder (used for initial bootstrap, now replaced by rosetta-builder)
              # nix.linux-builder.enable = true;

              # Rosetta-based builder: faster x86_64-linux builds using Rosetta 2
              # onDemand: VM starts only when needed and powers off when idle
              nix-rosetta-builder.enable = true;
              nix-rosetta-builder.onDemand = true;
            }
          ];
        };
      };
    };
}
