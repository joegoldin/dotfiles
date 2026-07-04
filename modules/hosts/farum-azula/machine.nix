# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  keys = import "${inputs.dotfiles-secrets}/keys.nix";
  cfTunnels = import "${inputs.dotfiles-secrets}/cloudflared.nix";
  username = meta.username;
in
{
  den.aspects.farum-azula.nixos =
    {
      config,
      lib,
      ...
    }:
    {
      users.users.root.openssh.authorizedKeys.keys = [
        keys.${username}
      ];

      # Set your time zone.
      time.timeZone = "America/Los_Angeles";

      services = {
        cloudflared = {
          enable = true;
          tunnels = {
            "${cfTunnels.bastion}" = {
              credentialsFile = config.age.secrets.cf.path;
              default = "http_status:404";
            };
          };
        };

        tailscale = {
          enable = true;
          useRoutingFeatures = "server";
        };
      };

      programs.ssh.startAgent = true;

      # Passwordless sudo for wheel — so remote `just build-to-farum-azula` runs
      # non-interactively, like the other servers.
      security.sudo.wheelNeedsPassword = false;

      # Full-disk encryption: unlock the LUKS root remotely over SSH in the initrd,
      # on :22 sharing the booted system's host key (deploy-farum-azula seeds the
      # same key into both, so known_hosts doesn't churn). On every boot the box
      # halts here until you `ssh root@farum-azula.turnin.quest` and enter the
      # passphrase. After boot, `ssh joe@…` works normally.
      boot.initrd = {
        systemd = {
          enable = true;
          # sshd prints /etc/motd on login; it names the command to unlock.
          contents."/etc/motd".text = ''

            🔒  ${config.networking.hostName}: root filesystem is encrypted and LOCKED.

                To unlock, run:   unlock

                Enter the LUKS passphrase; on success the system finishes booting
                and this SSH session closes. Wrong passphrase? Run it again.

          '';
        };
        # Oracle A1.Flex primary VNIC = virtio-net — needed in the initrd so the
        # SSH-unlock session has networking.
        availableKernelModules = [
          "virtio_net"
          "virtio_pci"
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
      boot.kernelParams = [ "ip=dhcp" ]; # bring up networking in the initrd

      # 8 GiB swap as a file on the (encrypted) root.
      swapDevices = [
        {
          device = "/swapfile";
          size = 8 * 1024;
        }
      ];

      # This option defines the first version of NixOS you have installed on this particular machine,
      # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
      #
      # Most users should NEVER change this value after the initial install, for any reason,
      # even if you've upgraded your system to a new NixOS release.
      #
      # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
      # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
      # to actually do that.
      #
      # This value being lower than the current NixOS release does NOT mean your system is
      # out of date, out of support, or vulnerable.
      #
      # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
      # and migrated your data accordingly.
      #
      # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
      # Fresh install off the nixos-26.05 flake — never change after install.
      system.stateVersion = lib.mkForce "26.05";
    };
}
