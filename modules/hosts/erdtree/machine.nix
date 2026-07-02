# Machine-specific config: root ssh key, timezone, cloudflared tunnel, tailscale,
# docker. The cloudflared tunnel is a general-purpose ingress for misc web
# services on this box; the Wings API itself is fronted by direct Caddy/LE (see
# wings.nix), since SFTP + game traffic can't ride Cloudflare.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  keys = import "${inputs.dotfiles-secrets}/keys.nix";
  cfTunnels = import "${inputs.dotfiles-secrets}/cloudflared.nix";
  username = meta.username;
in
{
  den.aspects.erdtree.nixos =
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
            # Tunnel ID lives in cloudflared.nix (replace the placeholder there
            # after `cloudflared tunnel create erdtree`); creds in erdtree-cf.json.age.
            "${cfTunnels.erdtree}" = {
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

      # Passwordless sudo for wheel — joe is key-only (no password on a fresh
      # install) and remote `just build-to-erdtree` needs non-interactive sudo.
      security.sudo.wheelNeedsPassword = false;

      virtualisation.docker.enable = true;
      users.extraGroups.docker.members = [ "${username}" ];

      # Full-disk encryption: unlock the LUKS root remotely over SSH in the
      # initrd, on :22 sharing the booted system's host key (deploy-erdtree seeds
      # the same key into both, so known_hosts doesn't churn). On every boot the
      # box halts here until you `ssh root@erdtree.turnin.quest` (authorized with
      # joe's key) and enter the passphrase (then `systemd-tty-ask-password-agent`
      # if not auto-prompted). After boot, `ssh joe@…` works normally on :22.
      boot.initrd = {
        systemd.enable = true;
        # NIC driver(s) for initrd networking — TRIM to erdtree's actual NIC once
        # known (check `lspci -k` / the generated hardware-config). This is a
        # broad bare-metal net so the box can come up to be unlocked.
        availableKernelModules = [
          "e1000e"
          "igb"
          "ixgbe"
          "r8169"
          "tg3"
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
