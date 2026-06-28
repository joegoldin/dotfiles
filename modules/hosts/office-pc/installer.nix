# Installer ISO for office-pc; an artifact build, not a machine, so it is a
# plain flake output rather than a den entity. It embeds the den-generated
# office-pc closure (self.nixosConfigurations.office-pc) plus all flake
# inputs for fully-offline disko-install. Verbatim from the old flake.nix.
{ inputs, ... }:
let
  inherit (inputs) self nixpkgs disko;
  meta = import ../../_lib/meta.nix;
  username = meta.username;
in
{
  flake.nixosConfigurations.office-pc-installer =
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
        ./_disk-config.nix
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
                # disko-install may unmount after finishing; re-mount for password step
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
}
