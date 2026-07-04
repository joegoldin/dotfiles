# Calagopus Wings node (wings-rs) on farum-azula — the Oracle Ampere box also runs
# a game-server node now, registered to the Calagopus panel on roundtable. Same
# shape as erdtree/siofra: daemon + Docker + TLS front + firewall; the node identity
# (panel remote, uuid, token, ports, allowed_mounts) lives in the panel-generated
# config.yml held in agenix at /etc/pterodactyl/config.yml (wings-rs's default path).
#
# ⚠ farum-azula is aarch64 (Ampere). The wings DAEMON is native aarch64, but game
# server Docker IMAGES must be arm64 (or they run under qemu emulation, slow) — use
# ARM-compatible eggs/images here, not the x86_64 ones erdtree/siofra run.
#
# TLS front for the Wings API on wings.farum-azula.turnin.quest (direct A → this
# box, Caddy/LE → :8080). SFTP (:2022) + game traffic are direct (can't ride the
# cloudflared tunnel). After deploy: create the node in the Calagopus panel (FQDN
# wings.farum-azula.turnin.quest, SSL/Behind-Proxy on, daemon 443 / API 8080, SFTP
# 2022), copy its config.yml → `agenix -e farum-azula-calagopus-config.age`, then
# build-to-farum-azula.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  dotfiles-secrets = inputs.dotfiles-secrets;
in
{
  den.aspects.farum-azula.nixos =
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
      age.secrets.farum-azula-calagopus-config = {
        file = "${dotfiles-secrets}/farum-azula-calagopus-config.age";
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
      # game-server containers run as. Declare it so `ensure_user` finds it instead
      # of shelling out to `useradd` (not in the service PATH / not the NixOS way).
      users.groups.pterodactyl = { };
      users.users.pterodactyl = {
        isSystemUser = true;
        group = "pterodactyl";
        description = "Calagopus Wings game-server user";
      };

      # Docker is required for Wings (was removed with Pelican; re-added here).
      virtualisation.docker.enable = true;

      # TLS front for the Wings API on the node's dedicated FQDN.
      services.caddy.enable = true;
      services.caddy.virtualHosts."${domains.farumAzulaWingsDomain}" = {
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
        # Game servers (same range as erdtree/siofra)
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
