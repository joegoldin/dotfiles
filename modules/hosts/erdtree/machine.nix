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

      # First NixOS release installed on this machine (fresh install off the
      # nixos-26.05 flake). Never change after install — see the NixOS manual.
      system.stateVersion = lib.mkForce "26.05";
    };
}
