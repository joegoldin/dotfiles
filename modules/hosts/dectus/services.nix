# Caddy reverse proxy + fail2ban jails (verbatim from the old
# hosts/dectus/services.nix). Merges into den.aspects.dectus
# alongside ./default.nix; one aspect, multiple files.
{ inputs, ... }:
let
  domains = import "${inputs.dotfiles-secrets}/domains.nix";
in
{
  den.aspects.dectus.nixos = {
    services.caddy = {
      enable = true;

      virtualHosts."${domains.jellyfinDomain}".extraConfig = ''
        log {
          output file /var/log/caddy/jellyfin-access.log
          format json
        }
        reverse_proxy http://${domains.roundtableTailscale}:8096 {
          header_up X-Real-IP {remote_host}
          header_up X-Forwarded-Proto {scheme}
        }
      '';

      virtualHosts."${domains.jellyseerrDomain}".extraConfig = ''
        log {
          output file /var/log/caddy/jellyseerr-access.log
          format json
        }
        reverse_proxy http://${domains.roundtableTailscale}:5055
      '';
    };

    systemd.tmpfiles.rules = [
      "d /var/log/caddy 0755 caddy caddy -"
    ];

    services.fail2ban = {
      enable = true;
      bantime = "1h";
      bantime-increment = {
        enable = true;
        maxtime = "24h";
      };
      jails.jellyfin-auth.settings = {
        enabled = true;
        filter = "jellyfin-auth";
        backend = "auto";
        logpath = "/var/log/caddy/jellyfin-access.log";
        maxretry = 10;
        findtime = 600;
        bantime = 3600;
      };
      jails.jellyseerr-auth.settings = {
        enabled = true;
        filter = "jellyseerr-auth";
        backend = "auto";
        logpath = "/var/log/caddy/jellyseerr-access.log";
        maxretry = 10;
        findtime = 600;
        bantime = 3600;
      };
    };

    environment.etc."fail2ban/filter.d/jellyfin-auth.conf".text = ''
      [Definition]
      failregex = ^.*"client_ip":"<HOST>".*"uri":"/Users/AuthenticateByName".*"status":401.*$
      ignoreregex =
    '';

    # Jellyseerr auth endpoints: /api/v1/auth/local (username+pw),
    # /api/v1/auth/plex, /api/v1/auth/jellyfin. 401/403 indicates failure.
    environment.etc."fail2ban/filter.d/jellyseerr-auth.conf".text = ''
      [Definition]
      failregex = ^.*"client_ip":"<HOST>".*"uri":"/api/v1/auth/(local|plex|jellyfin)".*"status":(401|403).*$
      ignoreregex =
    '';
  };
}
