# Pelican Panel and Wings configuration (standalone — erdtree's own panel).
#
# Create admin user:
#   cd /var/lib/pelican-panel
#   nix-shell -p php --run "sudo -u pelican-panel php /nix/store/*pelican-panel*/artisan p:user:make"
#
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  dotfiles-secrets = inputs.dotfiles-secrets;
in
{
  den.aspects.erdtree.nixos =
    {
      config,
      ...
    }:
    let
      domains = import "${dotfiles-secrets}/domains.nix";
      panelCfg = config.services.pelican.panel;
    in
    {
      # Fix missing group for redis
      users.groups.redis-pelican-panel = { };

      # Ensure pelican services wait for agenix secrets
      systemd.services = {
        pelican-panel-setup = {
          after = [ "agenix.service" ];
          wants = [ "agenix.service" ];
          # Re-add dependencies lost by enableNginx = false
          requiredBy = [ "phpfpm-pelican-panel.service" ];
          before = [ "phpfpm-pelican-panel.service" ];
        };
        pelican-wings-setup = {
          after = [ "agenix.service" ];
          wants = [ "agenix.service" ];
        };
        phpfpm-pelican-panel = {
          requires = [ "pelican-panel-setup.service" ];
        };
      };

      # PANEL - Game server management web interface
      services.pelican.panel = {
        enable = true;
        enableNginx = false;
        group = "caddy";
        app = {
          url = "https://${domains.erdtreePelicanDomain}";
          # Generate with: echo "base64:$(openssl rand -base64 32)"
          keyFile = config.age.secrets.erdtree-pelican-app-key.path;
        };
        database.passwordFile = config.age.secrets.erdtree-pelican-db-password.path;
        redis.passwordFile = config.age.secrets.erdtree-pelican-redis-password.path;
      };

      # PHP-FPM pool for Pelican Panel (replaces the one from enableNginx)
      services.phpfpm.pools.pelican-panel = {
        user = panelCfg.user;
        group = "caddy";
        phpPackage = panelCfg.phpPackage;
        settings = {
          "listen.owner" = "caddy";
          "listen.group" = "caddy";
          "pm" = "dynamic";
          "pm.max_children" = 5;
          "pm.start_servers" = 2;
          "pm.min_spare_servers" = 1;
          "pm.max_spare_servers" = 3;
        };
      };

      # Caddy serves the panel over HTTP on loopback; the cloudflared tunnel
      # provides the public HTTPS endpoint (pelican.erdtree.turnin.quest).
      services.caddy.enable = true;
      services.caddy.virtualHosts."http://${domains.erdtreePelicanDomain}" = {
        extraConfig = ''
          root * ${panelCfg.package}/public
          php_fastcgi unix/${config.services.phpfpm.pools.pelican-panel.socket}
          file_server
          encode gzip
          request_body {
            max_size 100MB
          }
        '';
      };

      # WINGS - Game server daemon (runs containers)
      services.pelican.wings = {
        enable = true;
        # Ports are controlled explicitly in the firewall block below, not by
        # the module (this host has no provider-side ACL).
        openFirewall = false;
        # TODO(deploy): replace with the node UUID generated when the Wings node
        # is created in erdtree's panel.
        uuid = "REPLACE-WITH-ERDTREE-WINGS-NODE-UUID";
        remote = "https://${domains.erdtreePelicanDomain}";
        tokenIdFile = config.age.secrets.erdtree-pelican-token-id.path;
        tokenFile = config.age.secrets.erdtree-pelican-token.path;
        # The module dropped the `allowedMounts` option; the equivalent Wings
        # config key `allowed_mounts` is now set through extraConfig (merged
        # into config.yml via recursiveUpdate).
        extraConfig.allowed_mounts = [ "/home/${meta.username}/pelican-mounts" ];
        system.sftp = {
          host = "0.0.0.0";
          port = 2022;
        };
      };

      # Docker is required for Wings
      virtualisation.docker.enable = true;

      # This host has NO provider-side network ACL, so the NixOS firewall below
      # is the ONLY gate on inbound traffic — every open port is declared here.
      networking.firewall = {
        enable = true;
        # tailnet trusted for admin/SSH; docker bridge for Wings containers.
        trustedInterfaces = [
          "tailscale0"
          "docker0"
        ];
        # Panel rides the cloudflared tunnel (Caddy on loopback), so no public
        # 80/443 — only SSH + Wings/SFTP + game ports are exposed directly.
        allowedTCPPorts = [
          22 # SSH
          8080 # Wings API (panel ↔ node)
          2022 # Wings SFTP
        ];
        # Game servers (same range on every host)
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

      # Ensure pelican directories exist
      system.activationScripts.pelicanDirs = ''
        mkdir -p /home/${meta.username}/pelican-mounts
        chown ${meta.username}:users /home/${meta.username}/pelican-mounts
        mkdir -p /etc/pelican
        chown pelican-wings:pelican-wings /etc/pelican
      '';

      # Secrets for Pelican (create these with agenix)
      # Generate secrets:
      #   App key: echo "base64:$(openssl rand -base64 32)" | agenix -e erdtree-pelican-app-key.age
      #   DB password: openssl rand -base64 32 | agenix -e erdtree-pelican-db-password.age
      #   Redis password: openssl rand -base64 32 | agenix -e erdtree-pelican-redis-password.age
      #   Token ID & Token: get these from the panel after creating a node
      age.secrets = {
        erdtree-pelican-app-key = {
          file = "${dotfiles-secrets}/erdtree-pelican-app-key.age";
          mode = "0644";
        };
        erdtree-pelican-db-password = {
          file = "${dotfiles-secrets}/erdtree-pelican-db-password.age";
          mode = "0644";
        };
        erdtree-pelican-redis-password = {
          file = "${dotfiles-secrets}/erdtree-pelican-redis-password.age";
          mode = "0644";
        };
        erdtree-pelican-token-id = {
          file = "${dotfiles-secrets}/erdtree-pelican-token-id.age";
          mode = "0644";
        };
        erdtree-pelican-token = {
          file = "${dotfiles-secrets}/erdtree-pelican-token.age";
          mode = "0644";
        };
      };
    };
}
