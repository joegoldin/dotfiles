{
  description = "Joe Goldin Nix Config";

  inputs = import ./inputs.nix;

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
      systems,
      pre-commit-hooks,
      nix-homebrew,
      disko,
      agenix,
      plasma-manager,
      erosanix,
      lanzaboote,
      dotfiles-assets,
      dotfiles-secrets,
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
      formatter = eachSystem (system: inputs.nixpkgs-unstable.legacyPackages.${system}.nixfmt);

      # Your custom packages and modifications, exported as overlays
      overlays = import ./hosts/common/system/overlays { inherit inputs; };

      checks = eachSystem (system: {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt.enable = true;
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
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = specialArgs;
                  backupFileExtension = "backup"; # enable moving existing files
                  users.${specialArgs.username} = import ./hosts/wsl/home-manager.nix;
                };
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
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = specialArgs;
                  backupFileExtension = "backup"; # enable moving existing files
                  users.${specialArgs.username} = import ./hosts/oracle-cloud/home-manager.nix;
                };
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
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = specialArgs;
                  backupFileExtension = "backup"; # enable moving existing files
                  users.${specialArgs.username} = import ./hosts/racknerd-cloud/home-manager.nix;
                };
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
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = specialArgs;
                  backupFileExtension = "backup"; # enable moving existing files
                  sharedModules = [
                    plasma-manager.homeModules.plasma-manager
                  ];
                  users.${specialArgs.username} = import ./hosts/nixos/home-manager.nix;
                };
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
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = specialArgs;
                  backupFileExtension = "backup"; # enable moving existing files
                  users.joe.imports = [
                    ./hosts/darwin/home-manager.nix
                  ];
                };
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
