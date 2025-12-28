{
  description = "Joe Goldin Nix Config";

  inputs = {
    # Nixpkgs
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.
    # nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # darwin
    nix-darwin = {
      # url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Home manager
    home-manager = {
      # url = "github:nix-community/home-manager/release-25.11";
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # wsl
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    # flake-utils
    flake-utils.url = "github:numtide/flake-utils";
    # systems
    systems.url = "github:nix-systems/default";
    # devenv
    devenv.url = "github:cachix/devenv";
    # nixpkgs-python
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
    # pre-commit-hooks
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    # brew-nix
    brew-nix = {
      url = "github:BatteredBunny/brew-nix";
      inputs.brew-api.follows = "brew-api";
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };
    # nix-homebrew
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
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
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # agenix
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # plasma-manager for KDE configuration
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    # affinity apps
    affinity-nix = {
      url = "github:mrshmllow/affinity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # for mkWindowsApp
    erosanix = {
      url = "github:emmanuelrosa/erosanix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # for secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # for codex
    nix-ai-tools.url = "github:numtide/nix-ai-tools";
    # assets (fonts, etc.)
    dotfiles-assets = {
      url = "git+file:assets";
      flake = false;
    };
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
    experimental-features = "nix-command flakes";
  };

  outputs = {
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
    nix-ai-tools,
    dotfiles-assets,
    ...
  } @ inputs: let
    inherit (self) outputs;
    username = "joe";
    useremail = "joe@joegold.in";
    hostname = "${username}-nix";
    homeDirectory = nixpkgs.lib.mkForce "/home/${username}";
    stateVersion = "24.11";
    commonSpecialArgs =
      inputs
      // {
        inherit inputs outputs useremail stateVersion username hostname homeDirectory dotfiles-assets;
      };
    eachSystem = nixpkgs.lib.genAttrs (import systems);
    basePackages = eachSystem (system: import ./environments/common/pkgs nixpkgs.legacyPackages.${system});
    additionalPackages = eachSystem (system: {
      # devenv-up = self.devShells.${system}.default.config.procfileScript;
    });
    mkWindowsApp = erosanix.mkWindowsApp;
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = eachSystem (system: basePackages.${system} // additionalPackages.${system});
    formatter = eachSystem (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Your custom packages and modifications, exported as overlays
    overlays = import ./environments/common/overlays {inherit inputs;};

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
        specialArgs =
          commonSpecialArgs
          // {
            hostname = "joe-wsl";
          };
        modules = [
          nixos-wsl.nixosModules.default
          # > Our main nixos configuration <
          ./environments/wsl
          home-manager.nixosModules.home-manager
          ({specialArgs, ...}: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.backupFileExtension = "backup"; # enable moving existing files
            home-manager.users.${specialArgs.username} = import ./home-manager/wsl;
          })
          agenix.nixosModules.default
        ];
      };

      oracle-cloud-bastion = nixpkgs.lib.nixosSystem {
        specialArgs =
          commonSpecialArgs
          // {
            hostname = "bastion";
          };
        modules = [
          disko.nixosModules.disko
          # > Our main nixos configuration <
          ./environments/oracle-cloud
          home-manager.nixosModules.home-manager
          ({specialArgs, ...}: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.backupFileExtension = "backup"; # enable moving existing files
            home-manager.users.${specialArgs.username} = import ./home-manager/oracle;
          })
          agenix.nixosModules.default
          ({specialArgs, ...}: {
            age.secrets.cf = {
              file = ./secrets/cf.json.age;
              mode = "655";
              owner = specialArgs.username;
              group = "users";
            };
            age.identityPaths = ["/home/joe/.ssh/id_ed25519"];
          })
        ];
      };

      # Desktop NixOS configuration
      joe-desktop = nixpkgs.lib.nixosSystem {
        specialArgs =
          commonSpecialArgs
          // {
            hostname = "joe-desktop";
            inherit inputs mkWindowsApp;
          };
        modules = [
          # > Our main nixos configuration <
          ./environments/nixos
          home-manager.nixosModules.home-manager
          ({specialArgs, ...}: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.backupFileExtension = "backup"; # enable moving existing files
            home-manager.sharedModules = [
              plasma-manager.homeModules.plasma-manager
            ];
            home-manager.users.${specialArgs.username} = import ./home-manager/nixos;
          })
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
        specialArgs =
          commonSpecialArgs
          // {
            username = "joe";
            hostname = "Joes-MacBook-Pro";
            homeDirectory = nixpkgs.lib.mkForce "/Users/joe";
          };
        modules = [
          # > Our main darwin configuration <
          ./environments/darwin
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          ({specialArgs, ...}: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.backupFileExtension = "backup"; # enable moving existing files
            home-manager.users.joe.imports = [
              ./home-manager/darwin
            ];
          })
          agenix.nixosModules.default
        ];
      };
    };
  };
}
