{
  description = "Joe Goldin Nix Config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";

    # darwin
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # wsl
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixos-wsl,
    darwin,
    ...
  } @ inputs: let
    inherit (self) outputs;
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    username = "joe";
    useremail = "joe@joegold.in";
    hostname = "${username}-desktop-nix";
    homeDirectory = nixpkgs.lib.mkForce "/home/${username}";
    stateVersion = "24.05";
    specialArgs =
      inputs
      // {
        inherit inputs outputs username useremail hostname homeDirectory stateVersion;
      };
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./environments/common/pkgs nixpkgs.legacyPackages.${system});
    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Your custom packages and modifications, exported as overlays
    overlays = import ./environments/common/overlays {inherit inputs;};

    devShells = forAllSystems (system: nixpkgs.legacyPackages.${system}.mkShell {
      name = "nix-dev-shell";
      buildInputs = [
        nixpkgs.legacyPackages.${system}.git
        nixpkgs.legacyPackages.${system}.nodejs
        nixpkgs.legacyPackages.${system}.yarn
        nixpkgs.legacyPackages.${system}.python312Full
        nixpkgs.legacyPackages.${system}.docker
        # Add any other packages you need for your development environment
      ];

      shellHook = ''
        echo "Welcome to the development shell!"
      '';
    });

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#joe-wsl'
    nixosConfigurations = {
      joe-wsl = nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        modules = [
          nixos-wsl.nixosModules.default
          # > Our main nixos configuration file <
          ./environments/wsl
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users.${specialArgs.username} = import ./home-manager/wsl;
          }
        ];
      };

      joe-nixos = nixpkgs.lib.nixosSystem {
        specialArgs =
          specialArgs
          // {
            hostname = "joe-nixos";
          };
        modules = [
          # > Our main nixos configuration file <
          ./environments/nixos
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users.${specialArgs.username} = import ./home-manager/nixos;
          }
        ];
      };
    };

    # Darwin/macOS configuration entrypoint
    # Available through 'darwin-rebuild --flake .#joe-macos'
    darwinConfigurations = {
      joe-macos = darwin.lib.darwinSystem {
        specialArgs =
          specialArgs
          // {
            username = "joegoldin";
            homeDirectory = nixpkgs.lib.mkForce "/Users/${specialArgs.username}";
          };
        modules = [
          ./environments/darwin
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users.${specialArgs.username} = import ./home-manager/darwin;
          }
        ];
      };
    };
  };
}