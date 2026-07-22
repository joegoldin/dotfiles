# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  keys = import "${inputs.dotfiles-secrets}/keys.nix";
  domains = import "${inputs.dotfiles-secrets}/domains.nix";
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
      assertions = [
        {
          assertion = !(lib.elem 9100 config.networking.firewall.allowedTCPPorts);
          message = "farum-azula node-exporter must not be globally exposed through allowedTCPPorts";
        }
      ];

      users.users.root.openssh.authorizedKeys.keys = [
        keys.${username}
      ];

      # Set your time zone.
      time.timeZone = "America/Los_Angeles";

      services.tailscale = {
        enable = true;
        useRoutingFeatures = "server";
      };

      # Builder metrics for garnix's operator-only Monitoring page. The
      # exporter must bind beyond loopback so erdtree can scrape it, but 9100
      # is deliberately absent from allowedTCPPorts: only the authenticated
      # tailnet and erdtree's stable public /32 may reach it.
      services.prometheus.exporters.node = {
        enable = true;
        listenAddress = "0.0.0.0";
        port = 9100;
        enabledCollectors = [ "systemd" ];
      };

      networking.firewall = {
        extraCommands = ''
          iptables -w -C nixos-fw -p tcp -s ${domains.garnixHostingPublicIp}/32 --dport 9100 -j nixos-fw-accept 2>/dev/null \
            || iptables -w -I nixos-fw 1 -p tcp -s ${domains.garnixHostingPublicIp}/32 --dport 9100 -j nixos-fw-accept
        '';
        extraStopCommands = ''
          iptables -w -D nixos-fw -p tcp -s ${domains.garnixHostingPublicIp}/32 --dport 9100 -j nixos-fw-accept 2>/dev/null \
            || true
        '';
      };

      # Independent service-boundary filtering protects the exporter even if
      # the host firewall is later broadened. tailscale0 is already a trusted
      # firewall interface; this CIDR admits every Tailscale IPv4 peer.
      systemd.services.prometheus-node-exporter.serviceConfig = {
        IPAddressDeny = "any";
        IPAddressAllow = [
          "localhost"
          "100.64.0.0/10"
          "${domains.garnixHostingPublicIp}/32"
        ];
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
