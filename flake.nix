{
  description = "Joe Goldin Nix Config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-24.11-darwin";
    # darwin
    nix-darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
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
    disko,
    agenix,
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
        inherit inputs outputs useremail stateVersion username hostname homeDirectory;
      };
    eachSystem = nixpkgs.lib.genAttrs (import systems);
    basePackages = eachSystem (system: import ./environments/common/pkgs nixpkgs.legacyPackages.${system});
    additionalPackages = eachSystem (system: {
      # devenv-up = self.devShells.${system}.default.config.procfileScript;
    });
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
            home-manager.users.${specialArgs.username} = import ./home-manager/nixos;
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
