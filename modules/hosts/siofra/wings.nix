# Calagopus Wings node (wings-rs) — registers to the Calagopus panel on
# roundtable (unraid). Replaces the old Pelican Wings on this box; the in-place
# cutover preserves siofra's running game server (its volume is moved to the new
# node's data dir, and the server is re-imported into Calagopus). See
# erdtree/wings.nix — this is the same daemon, just on siofra.
#
# The node identity (panel remote, uuid, token, ports, allowed_mounts) lives in
# the panel-generated config.yml, held in agenix and placed at
# /etc/pterodactyl/config.yml (wings-rs's default path). This module runs the
# daemon + provides Docker, the TLS front, and the firewall.
#
# The Wings API needs HTTPS for the panel's web console, so Caddy + Let's Encrypt
# fronts it on wings.siofra.turnin.quest → :443 → wings :8080 (off the base domain
# so siofra.turnin.quest's :443 stays free). SFTP (:2022) and game traffic are
# direct — they can't ride Cloudflare, and the node keeps the same game-port range
# (42420-42469) so players connect on the exact same address as before.
#
# Cutover: create the node in Calagopus (FQDN wings.siofra.turnin.quest, SSL +
# Behind-Proxy on, daemon port 443, API 8080, SFTP 2022), create the server there
# with allocations on the 42420-range, copy its config.yml →
# `agenix -e siofra-calagopus-config.age`. Then in the same maintenance window:
# stop the server in Pelican, move /var/lib/pelican-wings/volumes/<OLD_UUID> to the
# Calagopus data dir as <NEW_UUID> (chown pterodactyl), `just build-to-siofra`,
# start the server in Calagopus. (Assumes API :8080 / SFTP :2022 — adjust the Caddy
# target + firewall if you pick different ports.)
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  dotfiles-secrets = inputs.dotfiles-secrets;
in
{
  den.aspects.siofra.nixos =
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
      age.secrets.siofra-calagopus-config = {
        file = "${dotfiles-secrets}/siofra-calagopus-config.age";
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
      services.caddy.virtualHosts."${domains.siofraWingsDomain}" = {
        extraConfig = ''
          reverse_proxy localhost:8080
        '';
      };

      # No provider-side ACL — this firewall is the only gate on inbound traffic.
      networking.firewall = {
        enable = true;
        # tailnet trusted for admin/SSH; docker bridge for Wings containers.
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
        # Game servers (same range as before — players' address is unchanged)
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
