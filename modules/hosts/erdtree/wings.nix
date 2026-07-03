# Calagopus Wings node (wings-rs) — registers to the Calagopus panel on
# roundtable (unraid). Replaces the old Pelican Wings; erdtree is the first node
# on Calagopus (it has no servers, so this is a clean cut).
#
# The whole node identity (panel URL/remote, uuid, token, ports, allowed_mounts)
# lives in the panel-generated config.yml, held in agenix and placed at
# /etc/pterodactyl/config.yml (wings-rs's default path). This module just runs the
# daemon + provides Docker, the TLS front, and the firewall.
#
# The Wings API needs HTTPS for the panel's web console, so Caddy + Let's Encrypt
# fronts it on wings.erdtree.turnin.quest → :443 → wings :8080. SFTP (:2022) and
# game traffic are direct (can't ride Cloudflare).
#
# After deploy: create the node in the Calagopus panel (FQDN
# wings.erdtree.turnin.quest, SSL/Behind-Proxy on, daemon port 443, SFTP 2022),
# copy its config.yml → `agenix -e erdtree-calagopus-config.age`, then
# build-to-erdtree. (Assumes the panel config uses API :8080 / SFTP :2022 — adjust
# the Caddy target + firewall if you pick different ports.)
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  dotfiles-secrets = inputs.dotfiles-secrets;
in
{
  den.aspects.erdtree.nixos =
    {
      pkgs,
      lib,
      ...
    }:
    let
      domains = import "${dotfiles-secrets}/domains.nix";
    in
    {
      # The panel-generated node config (contains the node token) → the path
      # wings-rs reads by default. Real file (symlink off) so wings can rewrite it.
      age.secrets.erdtree-calagopus-config = {
        file = "${dotfiles-secrets}/erdtree-calagopus-config.age";
        path = "/etc/pterodactyl/config.yml";
        symlink = false;
        mode = "0600";
        owner = "root";
      };
      systemd.tmpfiles.rules = [ "d /etc/pterodactyl 0700 root root -" ];

      # WINGS - Calagopus daemon (runs the game-server containers). Systemd model
      # mirrors what `calagopus-wings service-install` generates.
      systemd.services.calagopus-wings = {
        description = "Calagopus Wings Daemon";
        after = [
          "docker.service"
          "agenix.service"
        ];
        requires = [ "docker.service" ];
        wants = [ "agenix.service" ];
        partOf = [ "docker.service" ];
        wantedBy = [ "multi-user.target" ];
        # backup/quota helpers wings shells out to (best-effort; docker is the hard dep)
        path = with pkgs; [
          docker
          restic
        ];
        serviceConfig = {
          User = "root";
          WorkingDirectory = "/etc/pterodactyl";
          ExecStart = lib.getExe pkgs.calagopus-wings;
          Restart = "on-failure";
          LimitNOFILE = 4096;
          RuntimeDirectory = "calagopus-wings";
          PIDFile = "/run/calagopus-wings/daemon.pid";
        };
      };

      # wings-rs's `system.username` (default "pterodactyl") is the uid that
      # game-server containers run as. On a normal host wings tries to create it
      # via `useradd` — which isn't in the service PATH (and isn't the NixOS way).
      # Declare it so `ensure_user` just finds it; wings then reads its uid/gid.
      users.groups.pterodactyl = { };
      users.users.pterodactyl = {
        isSystemUser = true;
        group = "pterodactyl";
        description = "Calagopus Wings game-server user";
      };

      # Docker is required for Wings
      virtualisation.docker.enable = true;

      # TLS front for the Wings API on the node's dedicated FQDN.
      services.caddy.enable = true;
      services.caddy.virtualHosts."${domains.erdtreeWingsDomain}" = {
        extraConfig = ''
          reverse_proxy localhost:8080
        '';
      };

      # No provider-side ACL — this firewall is the only gate on inbound traffic.
      networking.firewall = {
        enable = true;
        trustedInterfaces = [
          "tailscale0"
          "docker0"
        ];
        allowedTCPPorts = [
          22 # SSH
          80 # Let's Encrypt ACME HTTP-01 + redirect to 443
          443 # Wings API (Caddy → localhost:8080)
          2022 # Wings SFTP (direct; can't ride Cloudflare)
        ];
        allowedTCPPortRanges = [
          {
            from = 42420;
            to = 42469;
          }
        ];
        allowedUDPPortRanges = [
          {
            from = 42420;
            to = 42469;
          }
        ];
      };

      # Host dir Wings can bind-mount into containers (allowed_mounts in config.yml).
      system.activationScripts.calagopusMounts = ''
        mkdir -p /home/${meta.username}/calagopus-mounts
        chown ${meta.username}:users /home/${meta.username}/calagopus-mounts
      '';
    };
}
