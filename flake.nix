{
  description = "Joe Goldin Nix Config";

  inputs = {
    # ── Nixpkgs ─────────────────────────────────────────────────────────────
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";

    # ── Core framework ─────────────────────────────────────────────────────
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # darwin
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # wsl
    nixos-wsl.url = "github:nix-community/NixOS-WSL/release-25.11";

    # ── Local sources ───────────────────────────────────────────────────────
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

    # ── My repos ─────────────────────────────────────────────────────────────
    # recording + transcription CLI
    audiotools = {
      url = "github:joegoldin/audiotools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # claude-code wrapper in docker container with sandboxing
    claude-container = {
      url = "github:joegoldin/claude-container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # game server management
    pelican = {
      url = "github:joegoldin/nix-pelican?rev=900716d90d01a27666d65c9c112acde4c725ae9f";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Nix utilities ──────────────────────────────────────────────────────
    flake-utils.url = "github:numtide/flake-utils?ref=v1.0.0";
    systems.url = "github:nix-systems/default?rev=da67096a3b9bf56a91d16901293e51ba5b49a27e";
    # agenix
    agenix = {
      url = "github:ryantm/agenix?rev=b027ee29d959fda4b60b57566d64c98a202e0feb";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # disko
    disko = {
      url = "github:nix-community/disko?ref=v1.13.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # declarative flatpak management
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
    # fast x86_64-linux builds on Apple Silicon
    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder?rev=50e6070082e0b4fbaf67dd8f346892a1a9ed685c";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Development tools ──────────────────────────────────────────────────
    devenv.url = "github:cachix/devenv?ref=v1.11.2";
    nixpkgs-python.url = "github:cachix/nixpkgs-python?rev=0630618bfe33895453257fb606af75aa71247393";
    git-hooks.url = "github:cachix/git-hooks.nix?rev=5eaaedde414f6eb1aea8b8525c466dc37bba95ae";

    # ── Desktop / NixOS applications ───────────────────────────────────────
    # affinity apps
    affinity-nix = {
      url = "github:mrshmllow/affinity-nix?rev=cfec6b8371038868748370ed38c59ec35e49b62e";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Zed editor (built from source via flake)
    zed-editor.url = "github:zed-industries/zed";
    # KDE configuration
    plasma-manager = {
      url = "github:nix-community/plasma-manager?rev=44b928068359b7d2310a34de39555c63c93a2c90";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # ── Claude / LLM tooling ───────────────────────────────────────────────
    # Claude Code configuration library
    claude-nix = {
      url = "github:joegoldin/claude-nix?rev=337e48e08076a01c12a00290a318955e5e8bd6d2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # LLM agent tools (claude-code, codex, gemini-cli)
    llm-agents.url = "github:numtide/llm-agents.nix?rev=b9565d386f29e6b10cc7c513be3697e7c6694f9c";
    # declarative MCP server configuration
    mcps = {
      url = "github:roman/mcps.nix?rev=25acc4f20f5928a379e80341c788d80af46474b1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    # Claude Code skills
    superpowers = {
      url = "github:obra/superpowers?ref=v4.3.0";
      flake = false;
    };

    # ── Homebrew (macOS) ───────────────────────────────────────────────────
    nix-homebrew.url = "github:zhaofengli/nix-homebrew?rev=a5409abd0d5013d79775d3419bcac10eacb9d8c5";
    brew-nix = {
      url = "github:BatteredBunny/brew-nix?rev=b314426c17667bcebd73ed7e57ecae2bac9755cf";
      inputs.brew-api.follows = "brew-api";
    };
    brew-api = {
      url = "github:BatteredBunny/brew-api";
      flake = false;
    };

    # Official taps
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-services = {
      url = "github:homebrew/homebrew-services";
      flake = false;
    };

    # Third-party taps
    homebrew-argoproj = {
      url = "github:argoproj/homebrew-tap";
      flake = false;
    };
    homebrew-assemblyai = {
      url = "github:assemblyai/homebrew-assemblyai";
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
    homebrew-ibigio = {
      url = "github:ibigio/homebrew-tap";
      flake = false;
    };
    homebrew-k9s = {
      url = "github:derailed/homebrew-k9s";
      flake = false;
    };
    homebrew-neilberkman = {
      url = "github:neilberkman/homebrew-clippy";
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
    homebrew-vd = {
      url = "github:saulpw/homebrew-vd";
      flake = false;
    };
    homebrew-versent = {
      url = "github:versent/homebrew-taps";
      flake = false;
    };
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw= zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU= cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=";
    extra-substituters = "https://devenv.cachix.org https://zed.cachix.org https://cache.garnix.io";
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
      git-hooks,
      nix-homebrew,
      disko,
      agenix,
      plasma-manager,
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
      commonOverlays = builtins.attrValues self.overlays;
      commonSpecialArgs = inputs // {
        inherit
          inputs
          outputs
          commonOverlays
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
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = builtins.attrValues self.overlays;
            config.allowUnfree = true;
          };
        in
        import ./hosts/common/system/pkgs pkgs
      );
      additionalPackages = eachSystem (system: {
        # devenv-up = self.devShells.${system}.default.config.procfileScript;
      });
    in
    {
      # Your custom packages
      # Accessible through 'nix build', 'nix shell', etc
      packages = eachSystem (system: basePackages.${system} // additionalPackages.${system});
      formatter = eachSystem (system: inputs.nixpkgs-unstable.legacyPackages.${system}.nixfmt-tree);

      # Your custom packages and modifications, exported as overlays
      overlays = import ./hosts/common/system/overlays { inherit inputs; };

      checks = eachSystem (system: {
        pre-commit-check = git-hooks.lib.${system}.run {
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
