# ─────────────────────────────────────────────────────────────────────────────
# LEGACY HOSTS — verbatim from the pre-dendritic flake.nix (only the
# ./hosts/... paths were re-rooted and cloud-proxy removed).
#
# Hosts migrate out of here one at a time into den entities under
# modules/hosts/ (see MIGRATION.md). Already migrated: cloud-proxy.
# This file disappears when the last host leaves.
# ─────────────────────────────────────────────────────────────────────────────
{ inputs, ... }:
let
  inherit (inputs)
    self
    nixpkgs
    home-manager
    nix-darwin
    nix-homebrew
    disko
    agenix
    plasma-manager
    lanzaboote
    dotfiles-assets
    dotfiles-secrets
    pelican
    virby
    nix-flatpak
    nix-index-database
    ;
  inherit (self) outputs;
  username = "joe";
  useremail = "joe@joegold.in";
  hostname = "${username}-nix";
  homeDirectory = nixpkgs.lib.mkForce "/home/${username}";
  stateVersion = "24.11";
  overlaysModule = import ../../hosts/common/system/overlays { inherit inputs; };
  inherit (overlaysModule) unstableOverlays;
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
in
{
  flake.nixosConfigurations = {
    oracle-cloud-bastion = nixpkgs.lib.nixosSystem {
      specialArgs = commonSpecialArgs // {
        hostname = "bastion";
      };
      modules = [
        disko.nixosModules.disko
        nix-index-database.nixosModules.default
        pelican.nixosModules.default
        { nixpkgs.overlays = [ pelican.overlays.default ]; }
        # > Our main nixos configuration <
        ../../hosts/oracle-cloud
        home-manager.nixosModules.home-manager
        (
          { specialArgs, ... }:
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
              backupCommand = ''mv "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"''; # timestamped so reruns never collide
              users.${specialArgs.username} = import ../../hosts/oracle-cloud/home-manager.nix;
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
        inputs.attic.nixosModules.atticd
        # > Our main nixos configuration <
        ../../hosts/racknerd-cloud
        home-manager.nixosModules.home-manager
        (
          { specialArgs, ... }:
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
              backupCommand = ''mv "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"''; # timestamped so reruns never collide
              users.${specialArgs.username} = import ../../hosts/racknerd-cloud/home-manager.nix;
            };
          }
        )
        agenix.nixosModules.default
        (
          { specialArgs, ... }:
          {
            age.secrets.atticd-env = {
              file = "${dotfiles-secrets}/atticd.env.age";
              mode = "0400";
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
        # ROCm support only on desktop (has AMD GPU)
        # temporarily disabled — rocmSupport + vllm-rocm = 15h build
        {
          nixpkgs.overlays = [
            (final: prev: {
              unstable = import inputs.nixpkgs-unstable {
                inherit (final.stdenv.hostPlatform) system;
                config = {
                  allowUnfree = true;
                  android_sdk.accept_license = true;
                  # rocmSupport = true;
                };
                overlays = unstableOverlays;
                # overlays = unstableOverlays ++ [
                #   (import ../../hosts/common/system/overlays/vllm-rocm.nix)
                # ];
              };
            })
          ];
        }
        nix-index-database.nixosModules.default
        # > Our main nixos configuration <
        ../../hosts/nixos
        home-manager.nixosModules.home-manager
        (
          { specialArgs, ... }:
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
              backupCommand = ''mv "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"''; # timestamped so reruns never collide
              sharedModules = [
                plasma-manager.homeModules.plasma-manager
                nix-flatpak.homeManagerModules.nix-flatpak
              ];
              users.${specialArgs.username} = import ../../hosts/nixos/home-manager.nix;
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
            age.secrets.pixeldrain_api_key = {
              file = "${dotfiles-secrets}/pixeldrain_api_key.age";
              mode = "0400";
              owner = specialArgs.username;
            };
            age.secrets.anthropic_api_key = {
              file = "${dotfiles-secrets}/anthropic_api_key.age";
              mode = "0400";
              owner = specialArgs.username;
            };
            age.secrets.elevenlabs_api_key = {
              file = "${dotfiles-secrets}/elevenlabs_api_key.age";
              mode = "0400";
              owner = specialArgs.username;
            };
            age.secrets.wakapi_api_key = {
              file = "${dotfiles-secrets}/wakapi_api_key.age";
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
              owner = specialArgs.username;
            };
            age.secrets.atuin_key = {
              file = "${dotfiles-secrets}/atuin_key.age";
              mode = "0400";
              owner = specialArgs.username;
            };
          }
        )
        inputs.desk-phone.nixosModules.default
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
                overlays = unstableOverlays ++ [
                  (import ../../hosts/common/system/overlays/vllm-rocm.nix)
                ];
              };
            })
          ];
        }
        disko.nixosModules.disko
        nix-index-database.nixosModules.default
        ../../hosts/office-pc
        home-manager.nixosModules.home-manager
        (
          { specialArgs, ... }:
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
              backupCommand = ''mv "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"'';
              sharedModules = [
                plasma-manager.homeModules.plasma-manager
              ];
              users.${specialArgs.username} = import ../../hosts/office-pc/home-manager.nix;
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
            age.secrets.pixeldrain_api_key = {
              file = "${dotfiles-secrets}/pixeldrain_api_key.age";
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
              owner = specialArgs.username;
            };
          }
        )
        lanzaboote.nixosModules.lanzaboote
      ];
    };

    # Steam Deck with Jovian NixOS
    joe-steamdeck = nixpkgs.lib.nixosSystem {
      specialArgs = commonSpecialArgs // {
        hostname = "joe-steamdeck";
      };
      modules = [
        inputs.jovian-nixos.nixosModules.default
        nix-index-database.nixosModules.default
        ../../hosts/steamdeck
        home-manager.nixosModules.home-manager
        (
          { specialArgs, ... }:
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
              backupCommand = ''mv "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"'';
              sharedModules = [
                plasma-manager.homeModules.plasma-manager
                inputs.nix-attic-infra.homeManagerModules.attic-client
              ];
              users.${specialArgs.username} = import ../../hosts/steamdeck/home-manager.nix;
            };
          }
        )
        inputs.nix-attic-infra.nixosModules.attic-post-build-hook
        agenix.nixosModules.default
        (
          { specialArgs, ... }:
          {
            age.secrets.attic-netrc = {
              file = "${dotfiles-secrets}/attic-netrc.age";
              mode = "0400";
              owner = specialArgs.username;
            };
            age.secrets.attic-token = {
              file = "${dotfiles-secrets}/attic.token.age";
              mode = "0400";
              owner = specialArgs.username;
            };
          }
        )
      ];
    };

    # Installer ISO for office-pc
    office-pc-installer =
      let
        targetSystem = self.nixosConfigurations.office-pc;
        targetToplevel = targetSystem.config.system.build.toplevel;
        targetDisko = targetSystem.config.system.build.diskoScript;
        # Collect all flake input sources for offline evaluation
        allInputs = nixpkgs.lib.collect (x: x ? outPath) self.inputs;
      in
      nixpkgs.lib.nixosSystem {
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
          disko.nixosModules.disko
          ../../hosts/office-pc/disk-config.nix
          (
            { pkgs, ... }:
            {
              nixpkgs.hostPlatform = "x86_64-linux";
              networking.wireless.enable = nixpkgs.lib.mkForce false;
              networking.networkmanager.enable = true;

              # Disable Calamares installer autostart
              environment.etc."xdg/autostart/calamares.desktop".text = ''
                [Desktop Entry]
                Type=Application
                Name=Calamares
                Hidden=true
              '';

              # Enable flakes
              nix.settings.experimental-features = [
                "nix-command"
                "flakes"
              ];

              # Disable sleep/suspend/screen-off on live ISO
              services.logind.settings.Login.HandleLidSwitch = "ignore";
              systemd.targets.sleep.enable = false;
              systemd.targets.suspend.enable = false;
              systemd.targets.hibernate.enable = false;
              systemd.targets.hybrid-sleep.enable = false;
              environment.etc."xdg/powerdevilrc".text = ''
                [AC][DPMSControl]
                idleTimeout=0
                lockBeforeTurnOff=0
                [AC][SuspendAndShutdown]
                AutoSuspendAction=0
                PowerButtonAction=0
              '';
              services.logind.settings.Login = {
                IdleAction = "ignore";
                HandlePowerKey = "ignore";
              };

              # Auto-launch install-office-pc in Konsole
              environment.etc."xdg/autostart/install-office-pc.desktop".text = ''
                [Desktop Entry]
                Type=Application
                Name=Install Office PC
                Exec=kstart5 konsole -e install-office-pc
                X-KDE-autostart-phase=2
              '';

              environment.systemPackages = [
                pkgs.git
                pkgs.gh
                disko.packages.x86_64-linux.disko
                pkgs.sbctl
                pkgs.openssl
                pkgs.qrencode
                pkgs.kdePackages.kde-cli-tools
                (pkgs.writeShellScriptBin "install-office-pc" ''
                  LOGFILE="/tmp/install-office-pc.log"
                  exec > >(tee -a "$LOGFILE") 2>&1

                  on_error() {
                    echo ""
                    echo "========================================"
                    echo "  INSTALLATION FAILED"
                    echo "  Log saved to: $LOGFILE"
                    echo "========================================"
                    echo ""
                    if findmnt /mnt &>/dev/null; then
                      sudo cp "$LOGFILE" /mnt/var/log/install-office-pc.log 2>/dev/null || true
                      echo "  Log also saved to /mnt/var/log/install-office-pc.log"
                    fi
                    echo ""
                    echo "Press Enter to close..."
                    read -r
                    exit 1
                  }
                  trap on_error ERR

                  set -euo pipefail

                  pkill -f calamares 2>/dev/null || true

                  header() {
                    echo ""
                    echo "========================================"
                    echo "  $1"
                    echo "========================================"
                    echo ""
                  }

                  header "Step 1/5: LUKS Password"
                  read -s -p "Enter LUKS password: " LUKS_PASS
                  echo
                  read -s -p "Confirm LUKS password: " LUKS_PASS2
                  echo
                  if [ "$LUKS_PASS" != "$LUKS_PASS2" ]; then
                    echo "Passwords do not match!"
                    exit 1
                  fi
                  echo "$LUKS_PASS" > /tmp/luks-password

                  header "Step 2/5: Generate Secure Boot Keys"
                  SBKEYS_TMP=/tmp/sbctl-keys
                  sudo mkdir -p "$SBKEYS_TMP"/{PK,KEK,db}
                  for name in PK KEK db; do
                    echo "  Generating $name key..."
                    sudo openssl req -new -x509 -subj "/CN=$name/" -days 3650 -nodes \
                      -newkey rsa:4096 -sha256 \
                      -keyout "$SBKEYS_TMP/$name/$name.key" -out "$SBKEYS_TMP/$name/$name.pem" 2>/dev/null
                  done
                  echo "Secure Boot keys generated."

                  header "Step 3/5: Install NixOS (offline disko-install)"
                  echo "All store paths are baked into this ISO — no network needed."
                  echo "Target system: ${targetToplevel}"
                  echo ""
                  sudo disko-install \
                    --flake "${self}#office-pc" \
                    --disk main /dev/nvme1n1 \
                    --write-efi-boot-entries \
                    --extra-files "$SBKEYS_TMP" /var/lib/sbctl/keys

                  rm -f /tmp/luks-password
                  echo "disko-install succeeded."

                  header "Step 4/5: Set User Password"
                  echo "Re-mounting installed system..."
                  # disko-install may unmount after finishing — re-mount for password step
                  if ! findmnt /mnt &>/dev/null; then
                    sudo cryptsetup open /dev/disk/by-partlabel/disk-main-luks cryptroot 2>/dev/null || true
                    sudo vgchange -ay 2>/dev/null || true
                    sudo mount /dev/pool/root /mnt
                    sudo mount /dev/disk/by-partlabel/disk-main-ESP /mnt/boot
                  fi

                  echo "Set password for ${username}:"
                  if sudo nixos-enter --root /mnt -- passwd ${username}; then
                    echo "Password set successfully."
                  else
                    echo "nixos-enter failed, trying chroot..."
                    sudo chroot /mnt /bin/sh -c "echo '${username}:changeme' | chpasswd"
                    echo "Password set to 'changeme' — change it after first login!"
                  fi

                  sudo mkdir -p /mnt/var/log
                  sudo cp "$LOGFILE" /mnt/var/log/install-office-pc.log 2>/dev/null || true

                  header "Step 5/5: Done!"
                  echo "Rebooting in 10 seconds... (Ctrl+C to cancel)"
                  for i in $(seq 10 -1 1); do
                    printf "\r  %d..." "$i"
                    sleep 1
                  done
                  echo ""
                  sudo reboot
                '')
              ];

              # Force the target system closure into the ISO by referencing it
              # This makes nix include all store paths in the squashfs
              # Bake the target system closure and all flake inputs into the ISO
              isoImage.storeContents = [
                targetToplevel
                targetDisko
              ]
              ++ allInputs;
            }
          )
        ];
      };
  };

  # Darwin/macOS configuration entrypoint
  # Available through 'darwin-rebuild --flake .#Joes-MacBook-Pro'
  flake.darwinConfigurations = {
    Joes-MacBook-Pro = nix-darwin.lib.darwinSystem {
      specialArgs = commonSpecialArgs // {
        username = "joe";
        hostname = "Joes-MacBook-Pro";
        homeDirectory = nixpkgs.lib.mkForce "/Users/joe";
      };
      modules = [
        # > Our main darwin configuration <
        ../../hosts/darwin
        nix-index-database.darwinModules.default
        nix-homebrew.darwinModules.nix-homebrew
        # vfkit-based Linux builder (enabled below, currently kept off for bootstrap)
        virby.darwinModules.default
        home-manager.darwinModules.home-manager
        (
          { specialArgs, ... }:
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
              backupCommand = ''mv "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"''; # timestamped so reruns never collide
              users.joe.imports = [
                ../../hosts/darwin/home-manager.nix
              ];
            };
          }
        )
        agenix.darwinModules.default
        (
          { specialArgs, ... }:
          {
            age.identityPaths = [ "/var/lib/agenix/identity" ];
            age.secrets.attic-netrc = {
              file = "${dotfiles-secrets}/attic-netrc.age";
              mode = "0400";
              owner = specialArgs.username;
            };
            age.secrets.attic-token = {
              file = "${dotfiles-secrets}/attic.token.age";
              mode = "0400";
              owner = specialArgs.username;
            };
            age.secrets.wakapi_api_key = {
              file = "${dotfiles-secrets}/wakapi_api_key.age";
              mode = "0400";
            };
            age.secrets.atuin_key = {
              file = "${dotfiles-secrets}/atuin_key.age";
              mode = "0400";
              owner = specialArgs.username;
            };
            age.secrets.deepgram_api_key = {
              file = "${dotfiles-secrets}/deepgram_api_key.age";
              mode = "0400";
              owner = specialArgs.username;
            };
            age.secrets.pixeldrain_api_key = {
              file = "${dotfiles-secrets}/pixeldrain_api_key.age";
              mode = "0400";
              owner = specialArgs.username;
            };
            age.secrets.elevenlabs_api_key = {
              file = "${dotfiles-secrets}/elevenlabs_api_key.age";
              mode = "0400";
              owner = specialArgs.username;
            };
          }
        )
        {
          # vfkit-based Linux builder. The stock nix.linux-builder is kept off;
          # it was only used to bootstrap this rebuild (it builds virby's VM
          # image, then virby takes over as the aarch64-/x86_64-linux builder).
          nix.linux-builder.enable = false;
          services.virby = {
            enable = true;
            # Start the VM on demand and power it down after idle (parity with
            # the old rosetta-builder onDemand setup).
            onDemand.enable = true;
            # Build x86_64-linux via Rosetta translation (aarch64-darwin only).
            rosetta = true;
          };
        }
      ];
    };
  };
}
