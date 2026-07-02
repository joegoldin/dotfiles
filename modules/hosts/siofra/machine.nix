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
  den.aspects.siofra.nixos =
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
            # after `cloudflared tunnel create siofra`); creds in siofra-cf.json.age.
            "${cfTunnels.siofra}" = {
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
      # install) and remote `just build-to-siofra` needs non-interactive sudo.
      security.sudo.wheelNeedsPassword = false;

      virtualisation.docker.enable = true;
      users.extraGroups.docker.members = [ "${username}" ];

      # Full-disk encryption: unlock the LUKS root remotely over SSH in the
      # initrd, on :22 sharing the booted system's host key (deploy-siofra seeds
      # the same key into both, so known_hosts doesn't churn). On every boot the
      # box halts here until you `ssh root@siofra.turnin.quest` (authorized with
      # joe's key) and enter the passphrase (then `systemd-tty-ask-password-agent`
      # if not auto-prompted). After boot, `ssh joe@…` works normally on :22.
      boot.initrd = {
        systemd = {
          enable = true;
          # On SSH into the initrd, show a banner and auto-answer the pending LUKS
          # passphrase prompt (the initrd shell is a login shell, so it sources
          # /root/.profile). Ctrl-C drops to a rescue shell.
          contents."/etc/motd".text = ''

            🔒  ${config.networking.hostName}: root filesystem is encrypted and LOCKED.
                Enter the LUKS passphrase to unlock and continue booting.
                (Ctrl-C for a rescue shell.)

          '';
          contents."/root/.profile".text = ''
            cat /etc/motd
            # --watch keeps prompting: re-asks on a wrong passphrase, and blocks
            # until the root unlocks (boot proceeds → this session is torn down).
            systemd-tty-ask-password-agent --watch
          '';
        };
        availableKernelModules = [ "virtio_net" ]; # NIC driver, for initrd networking
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

      # First NixOS release installed on this machine (fresh install off the
      # nixos-26.05 flake). Never change after install — see the NixOS manual.
      system.stateVersion = lib.mkForce "26.05";
    };
}
