# Machine-specific config: root ssh key, timezone, static LAN IP, tailscale,
# docker, AMD microcode/firmware.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  keys = import "${inputs.dotfiles-secrets}/keys.nix";
  username = meta.username;
in
{
  den.aspects.melina.nixos =
    { config, lib, ... }:
    {
      users.users.root.openssh.authorizedKeys.keys = [
        keys.${username}
      ];

      users.users.${meta.username}.extraGroups = [
        "docker"
        "wheel"
      ];

      time.timeZone = "America/Los_Angeles";

      # AMD Ryzen: CPU microcode + redistributable firmware (Radeon iGPU, etc.)
      hardware.enableRedistributableFirmware = true;
      hardware.cpu.amd.updateMicrocode = true;

      # BlueZ on the host — Home Assistant's Bluetooth integration talks to it
      # over the /run/dbus mount (the box was running BT on Ubuntu).
      hardware.bluetooth.enable = true;

      # Static LAN IP (the box was DHCP→192.168.0.236; pin it so Home Assistant
      # integrations that reference the IP keep working). Confirm the interface
      # name is enp1s0 after install (Intel I225-V) and adjust if it differs.
      networking = {
        useDHCP = lib.mkForce false;
        interfaces.enp1s0.ipv4.addresses = [
          {
            address = "192.168.0.236";
            prefixLength = 24;
          }
        ];
        defaultGateway = "192.168.0.1";
        nameservers = [
          "192.168.0.1"
          "1.1.1.1"
        ];
      };

      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };

      programs.ssh.startAgent = true;

      # Passwordless sudo for wheel — joe is key-only (no password), and
      # `just build-to-melina` needs non-interactive sudo.
      security.sudo.wheelNeedsPassword = false;

      virtualisation.docker.enable = true;
      users.extraGroups.docker.members = [ "${username}" ];

      # Full-disk encryption: unlock the LUKS root remotely over SSH in the
      # initrd, on :22 sharing the booted system's host key (deploy-melina seeds
      # the same key into both, so known_hosts doesn't churn). On every boot the
      # box halts here until you `ssh root@192.168.0.236` (LAN only — the initrd
      # has no tailscale) and enter the passphrase. After boot, `ssh joe@…` works.
      boot.initrd = {
        systemd = {
          enable = true;
          # sshd prints /etc/motd on login; it names the command to unlock.
          contents."/etc/motd".text = ''

            🔒  ${config.networking.hostName}: root filesystem is encrypted and LOCKED.

                To unlock, run:   systemd-tty-ask-password-agent

                Enter the LUKS passphrase; on success the system finishes booting
                and this SSH session closes. Wrong passphrase? Run it again.

          '';
        };
        # igc = Intel I225-V NIC (initrd networking for the unlock); nvme so
        # stage-1 can see the disk to unlock the encrypted root.
        availableKernelModules = [
          "igc"
          "nvme"
        ];
        network = {
          enable = true;
          ssh = {
            enable = true;
            port = 22;
            authorizedKeys = [ keys.${username} ];
            hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
          };
        };
      };
      # Bring up networking in the initrd. DHCP relies on the router giving this
      # box its usual 192.168.0.236 (it has been consistently); if the initrd ends
      # up on a different IP, switch this to a static ip=192.168.0.236::… form.
      boot.kernelParams = [ "ip=dhcp" ];

      # 16 GiB swap as a file on the (encrypted) root.
      swapDevices = [
        {
          device = "/swapfile";
          size = 16 * 1024;
        }
      ];

      # First NixOS release installed on this machine (fresh install off the
      # nixos-26.05 flake). Never change after install — see the NixOS manual.
      system.stateVersion = lib.mkForce "26.05";
    };
}
