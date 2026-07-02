# Machine-specific config: root ssh key, timezone, cloudflared tunnel (for the
# Pelican panel), tailscale, docker.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  keys = import "${inputs.dotfiles-secrets}/keys.nix";
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
            # TODO(deploy): `cloudflared tunnel create siofra` → replace this
            # UUID + put the creds JSON in siofra-cf.json.age; then
            # `cloudflared tunnel route dns siofra pelican.siofra.turnin.quest`
            # (or add the public hostname → http://localhost:80 in the dashboard).
            "REPLACE-WITH-SIOFRA-TUNNEL-UUID" = {
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

      virtualisation.docker.enable = true;
      users.extraGroups.docker.members = [ "${username}" ];

      # First NixOS release installed on this machine (fresh install off the
      # nixos-26.05 flake). Never change after install — see the NixOS manual.
      system.stateVersion = lib.mkForce "26.05";
    };
}
