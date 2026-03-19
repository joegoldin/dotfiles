{
  description = "Joe Goldin Nix Config";

  inputs = {
    self.submodules = true;

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
      url = "./assets";
      flake = false;
    };
    # secrets (domains, encrypted age files, etc.)
    dotfiles-secrets = {
      url = "./secrets";
      flake = false;
    };

    # ── My repos ─────────────────────────────────────────────────────────────
    # recording + transcription CLI
    audiomemo = {
      url = "github:joegoldin/audiomemo";
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

    # ── Server services ────────────────────────────────────────────────────
    # binary cache server
    attic = {
      url = "github:joegoldin/attic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # attic infrastructure (client modules, post-build hooks)
    nix-attic-infra = {
      url = "github:joegoldin/nix-attic-infra";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.attic.follows = "attic";
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
    # pre-built nix-index database
    nix-index-database = {
      url = "github:nix-community/nix-index-database?rev=8faeb68130df077450451b6734a221ba0d6cde42";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # fast x86_64-linux builds on Apple Silicon
    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder?rev=50e6070082e0b4fbaf67dd8f346892a1a9ed685c";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Development tools ──────────────────────────────────────────────────
    devenv.url = "github:cachix/devenv?ref=v2.0.5";
    nixpkgs-python.url = "github:cachix/nixpkgs-python?rev=f31232bde73682c38a6f60dd52f8ae861ef9594a";
    git-hooks.url = "github:cachix/git-hooks.nix?rev=8baab586afc9c9b57645a734c820e4ac0a604af9";

    # ── Desktop / NixOS applications ───────────────────────────────────────
    # affinity apps
    affinity-nix = {
      url = "github:mrshmllow/affinity-nix?rev=6117ea7c0ca0e641b4ad1df89d7f47568eacb4b3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Ghostty terminal
    ghostty.url = "github:ghostty-org/ghostty?rev=d3bd224081d3c7c5ee54df6815e44f0b5d25357b";
    # Zed editor (built from source via flake)
    zed-editor.url = "github:zed-industries/zed?ref=v0.228.0-pre";
    # KDE configuration
    plasma-manager = {
      url = "github:nix-community/plasma-manager?rev=a4b33606111c9c5dcd10009042bb710307174f51";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # ── Claude / LLM tooling ───────────────────────────────────────────────
    # Claude Desktop for Linux
    claude-desktop-debian = {
      url = "github:aaddrick/claude-desktop-debian?rev=d6e6c9c7ffd3bbf9a22a01cb0dc3535a11422575";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Claude Code configuration library
    claude-nix = {
      url = "github:joegoldin/claude-nix?rev=337e48e08076a01c12a00290a318955e5e8bd6d2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # LLM agent tools (claude-code, codex, gemini-cli)
    llm-agents.url = "github:numtide/llm-agents.nix?rev=7509c7ed545ea3b5f11f8ed8a7efa7591157c9c8";
    # declarative MCP server configuration
    mcps = {
      url = "github:roman/mcps.nix?rev=25acc4f20f5928a379e80341c788d80af46474b1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    # Claude Code agent skills
    agent-skills = {
      url = "github:joegoldin/agent-skills";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Homebrew (macOS) ───────────────────────────────────────────────────
    nix-homebrew.url = "github:zhaofengli/nix-homebrew?rev=a5409abd0d5013d79775d3419bcac10eacb9d8c5";
    brew-nix = {
      url = "github:BatteredBunny/brew-nix?rev=6fcb48f460c97ba65a9ce94f8c841b36f53122fc";
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
    extra-trusted-public-keys = "";
    extra-substituters = "";
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
      nix-index-database,
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
      keys = import "${dotfiles-secrets}/keys.nix";
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
          keys
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
            nix-index-database.nixosModules.default
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
            (
              { ... }:
              {
                age.secrets.attic-netrc = {
                  file = "${dotfiles-secrets}/attic-netrc.age";
                  mode = "0400";
                };
              }
            )
          ];
        };

        oracle-cloud-bastion = nixpkgs.lib.nixosSystem {
          specialArgs = commonSpecialArgs // {
            hostname = "bastion";
          };
          modules = [
            disko.nixosModules.disko
            nix-index-database.nixosModules.default
            pelican.nixosModules.default
            { nixpkgs.overlays = [ pelican.overlays.default ]; }
            inputs.attic.nixosModules.atticd
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
                age.secrets.atticd-env = {
                  file = "${dotfiles-secrets}/atticd.env.age";
                  mode = "0400";
                  owner = "root";
                  group = "root";
                };
                age.secrets.attic-netrc = {
                  file = "${dotfiles-secrets}/attic-netrc.age";
                  mode = "0400";
                };
                age.identityPaths = [ "/home/${specialArgs.username}/.ssh/id_ed25519" ];
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
            nix-index-database.nixosModules.default
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
                age.secrets.attic-netrc = {
                  file = "${dotfiles-secrets}/attic-netrc.age";
                  mode = "0400";
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
            # ROCm support only on desktop (has AMD GPU)
            {
              nixpkgs.overlays = [
                (final: prev: {
                  unstable = import inputs.nixpkgs-unstable {
                    inherit (final.stdenv.hostPlatform) system;
                    config = {
                      allowUnfree = true;
                      android_sdk.accept_license = true;
                      rocmSupport = true;
                    };
                    overlays = [
                      (import ./hosts/common/system/overlays/vllm-rocm.nix)
                    ];
                  };
                })
              ];
            }
            nix-index-database.nixosModules.default
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
                    nix-flatpak.homeManagerModules.nix-flatpak
                  ];
                  users.${specialArgs.username} = import ./hosts/nixos/home-manager.nix;
                };
              }
            )
            nix-flatpak.nixosModules.nix-flatpak
            inputs.nix-attic-infra.nixosModules.attic-post-build-hook
            agenix.nixosModules.default
            (
              { specialArgs, ... }:
              {
                age.secrets.deepgram_api_key = {
                  file = "${dotfiles-secrets}/deepgram_api_key.age";
                  mode = "0400";
                  owner = specialArgs.username;
                };
                age.secrets.anthropic_api_key = {
                  file = "${dotfiles-secrets}/anthropic_api_key.age";
                  mode = "0400";
                  owner = specialArgs.username;
                };
                age.secrets.attic-token = {
                  file = "${dotfiles-secrets}/attic.token.age";
                  mode = "0400";
                  owner = specialArgs.username;
                };
                age.secrets.attic-netrc = {
                  file = "${dotfiles-secrets}/attic-netrc.age";
                  mode = "0400";
                };
              }
            )
            lanzaboote.nixosModules.lanzaboote
          ];
        };

        # office-pc compute/training machine
        office-pc = nixpkgs.lib.nixosSystem {
          specialArgs = commonSpecialArgs // {
            hostname = "office-pc";
          };
          modules = [
            # ROCm support (AMD GPU)
            {
              nixpkgs.overlays = [
                (final: prev: {
                  unstable = import inputs.nixpkgs-unstable {
                    inherit (final.stdenv.hostPlatform) system;
                    config = {
                      allowUnfree = true;
                      rocmSupport = true;
                    };
                    overlays = [
                      (import ./hosts/common/system/overlays/vllm-rocm.nix)
                    ];
                  };
                })
              ];
            }
            disko.nixosModules.disko
            nix-index-database.nixosModules.default
            ./hosts/office-pc
            home-manager.nixosModules.home-manager
            (
              { specialArgs, ... }:
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = specialArgs;
                  backupFileExtension = "backup";
                  sharedModules = [
                    plasma-manager.homeModules.plasma-manager
                  ];
                  users.${specialArgs.username} = import ./hosts/office-pc/home-manager.nix;
                };
              }
            )
            inputs.nix-attic-infra.nixosModules.attic-post-build-hook
            agenix.nixosModules.default
            (
              { specialArgs, ... }:
              {
                age.secrets.deepgram_api_key = {
                  file = "${dotfiles-secrets}/deepgram_api_key.age";
                  mode = "0400";
                  owner = specialArgs.username;
                };
                age.secrets.anthropic_api_key = {
                  file = "${dotfiles-secrets}/anthropic_api_key.age";
                  mode = "0400";
                  owner = specialArgs.username;
                };
                age.secrets.attic-token = {
                  file = "${dotfiles-secrets}/attic.token.age";
                  mode = "0400";
                  owner = specialArgs.username;
                };
                age.secrets.attic-netrc = {
                  file = "${dotfiles-secrets}/attic-netrc.age";
                  mode = "0400";
                };
              }
            )
            lanzaboote.nixosModules.lanzaboote
          ];
        };

        # Installer ISO for office-pc
        office-pc-installer = nixpkgs.lib.nixosSystem {
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
            disko.nixosModules.disko
            ./hosts/office-pc/disk-config.nix
            (
              { pkgs, ... }:
              let
                diskoScript = self.nixosConfigurations.office-pc.config.system.build.diskoScript;
                domains = import "${dotfiles-secrets}/domains.nix";
                attic = import "${dotfiles-secrets}/attic.nix";
                # Netrc is decrypted before build via Justfile (1Password flow) and placed at /tmp/attic-netrc
                netrc = builtins.path {
                  path = /tmp/attic-netrc;
                  name = "attic-netrc";
                };
                atticUrl = "https://${domains.atticDomain}/${attic.cacheName}";
                atticKey = attic.publicKey;
              in
              {
                nixpkgs.hostPlatform = "x86_64-linux";
                networking.wireless.enable = nixpkgs.lib.mkForce false;
                networking.networkmanager.enable = true;

                environment.systemPackages = [
                  pkgs.git
                  pkgs.gh
                  disko.packages.x86_64-linux.disko
                  pkgs.nix-output-monitor
                  pkgs.sbctl
                  (pkgs.writeShellScriptBin "install-office-pc" ''
                    set -euo pipefail

                    # Step 1: Authenticate with GitHub
                    NEW_KEY_ID=""
                    if gh auth status &>/dev/null; then
                      echo "Already authenticated with GitHub."
                      if ! gh api /user/keys &>/dev/null || ! gh api /user/ssh_signing_keys &>/dev/null; then
                        echo "Missing required scopes, refreshing..."
                        gh auth refresh -s admin:public_key -s admin:ssh_signing_key
                      fi
                      echo ""
                      echo "SSH keys on your account:"
                      gh ssh-key list
                      echo ""
                      read -p "Enter key ID to delete after install (or leave blank to skip): " NEW_KEY_ID
                    else
                      echo "Authenticating with GitHub..."
                      KEYS_BEFORE=$(gh api /user/keys --jq '.[].id' 2>/dev/null || true)
                      gh auth login -p ssh -s admin:public_key -s admin:ssh_signing_key
                      KEYS_AFTER=$(gh api /user/keys --jq '.[].id')
                      NEW_KEY_ID=$(comm -13 <(echo "$KEYS_BEFORE" | sort) <(echo "$KEYS_AFTER" | sort))
                    fi

                    # Step 2: Clone dotfiles and sync submodules
                    DOTFILES=/tmp/dotfiles
                    if [ -d "$DOTFILES" ]; then
                      echo "Dotfiles already cloned, pulling latest..."
                      git -C "$DOTFILES" pull
                    else
                      echo "Cloning dotfiles..."
                      git clone https://github.com/joegoldin/dotfiles.git "$DOTFILES"
                    fi
                    cd "$DOTFILES"
                    git submodule sync --recursive
                    git submodule update --init --recursive

                    # Step 3: Partition disk (skip if already mounted)
                    if findmnt /mnt &>/dev/null; then
                      echo "Disk already mounted at /mnt, skipping format."
                    else
                      read -p "This will ERASE /dev/nvme1n1. Continue? [y/N] " CONFIRM
                      if [[ "$CONFIRM" != [yY] ]]; then
                        echo "Aborted."
                        exit 1
                      fi
                      read -s -p "Enter LUKS password: " LUKS_PASS
                      echo
                      read -s -p "Confirm LUKS password: " LUKS_PASS2
                      echo
                      if [ "$LUKS_PASS" != "$LUKS_PASS2" ]; then
                        echo "Passwords do not match!"
                        exit 1
                      fi
                      echo "$LUKS_PASS" > /tmp/luks-password

                      echo "Partitioning /dev/nvme1n1 with disko..."
                      sudo ${diskoScript}

                      rm -f /tmp/luks-password
                    fi

                    # Step 4: Create Secure Boot keys for Lanzaboote
                    # sbctl doesn't work on live ISO, generate keys manually
                    SBKEYS=/mnt/var/lib/sbctl/keys
                    if [ ! -f "$SBKEYS/db/db.key" ]; then
                      sudo mkdir -p "$SBKEYS"/{PK,KEK,db}
                      for name in PK KEK db; do
                        sudo openssl req -new -x509 -subj "/CN=$name/" -days 3650 -nodes \
                          -newkey rsa:4096 -sha256 \
                          -keyout "$SBKEYS/$name/$name.key" -out "$SBKEYS/$name/$name.pem"
                      done
                      echo "Secure Boot keys generated."
                    else
                      echo "Secure Boot keys already exist, skipping."
                    fi || true

                    # Step 5: Install NixOS
                    echo "Installing NixOS..."
                    NIX_CONFIG="extra-experimental-features = nix-command flakes"
                    NIX_CONFIG="$NIX_CONFIG"$'\n'"access-tokens = github.com=$(gh auth token)"
                    NIX_CONFIG="$NIX_CONFIG"$'\n'"accept-flake-config = true"
                    NIX_CONFIG="$NIX_CONFIG"$'\n'"extra-substituters = ${atticUrl}"
                    NIX_CONFIG="$NIX_CONFIG"$'\n'"extra-trusted-public-keys = ${atticKey}"
                    NIX_CONFIG="$NIX_CONFIG"$'\n'"netrc-file = ${netrc}"
                    export NIX_CONFIG

                    sudo mkdir -p /root/.ssh
                    sudo cp ~/.ssh/id_ed25519 /root/.ssh/
                    sudo chmod 600 /root/.ssh/id_ed25519
                    sudo ssh-keyscan github.com 2>/dev/null | sudo tee /root/.ssh/known_hosts >/dev/null

                    # Move nix store writable layer to target disk to avoid tmpfs space issues
                    sudo mkdir -p /mnt/nix-rw-store
                    sudo mount --bind /mnt/nix-rw-store /nix/.rw-store
                    sudo prlimit --nofile=1048576 --pid=$$

                    sudo --preserve-env=NIX_CONFIG nixos-install --flake "$DOTFILES#office-pc" --no-root-passwd --no-channel-copy 2>&1 | nom

                    # Step 5: Clean up
                    sudo umount /nix/.rw-store || true
                    sudo rm -rf /mnt/nix-rw-store

                    if [ -n "$NEW_KEY_ID" ]; then
                      echo "Removing temporary SSH key from GitHub"
                      gh ssh-key delete "$NEW_KEY_ID" --yes
                    fi

                    echo "Done! You can reboot now."
                  '')
                ];
              }
            )
          ];
        };
      };

      # Darwin/macOS configuration entrypoint
      # Available through 'darwin-rebuild --flake .#Joes-MacBook-Pro'
      darwinConfigurations = {
        Joes-MacBook-Pro = nix-darwin.lib.darwinSystem {
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
            (
              { ... }:
              {
                age.secrets.attic-netrc = {
                  file = "${dotfiles-secrets}/attic-netrc.age";
                  mode = "0400";
                };
              }
            )
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
