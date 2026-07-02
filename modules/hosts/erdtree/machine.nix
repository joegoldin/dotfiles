# Machine-specific config: root ssh key, timezone, tailscale, docker.
# (Wings node — no cloudflared; the Wings API is fronted by Caddy/LE, see
# wings.nix.)
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  keys = import "${inputs.dotfiles-secrets}/keys.nix";
  username = meta.username;
in
{
  den.aspects.erdtree.nixos =
    { lib, ... }:
    {
      users.users.root.openssh.authorizedKeys.keys = [
        keys.${username}
      ];

      # Set your time zone.
      time.timeZone = "America/Los_Angeles";

      services.tailscale = {
        enable = true;
        useRoutingFeatures = "server";
      };

      programs.ssh.startAgent = true;

      virtualisation.docker.enable = true;
      users.extraGroups.docker.members = [ "${username}" ];

      # First NixOS release installed on this machine (fresh install off the
      # nixos-26.05 flake). Never change after install — see the NixOS manual.
      system.stateVersion = lib.mkForce "26.05";
    };
}
