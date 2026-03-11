# YepAnywhere relay server on bastion with Caddy HTTPS
{
  pkgs,
  dotfiles-secrets,
  ...
}:
let
  domains = import "${dotfiles-secrets}/domains.nix";
  yepRelayDomain = domains.yepRelayDomain;
  internalPort = "4400";
  yepanywhere-remote = pkgs.callPackage ../common/system/pkgs/yepanywhere-remote {
    defaultRelayUrl = "wss://${yepRelayDomain}/ws";
  };
in
{
  imports = [ ../common/system/pkgs/yepanywhere-relay/module.nix ];

  services.yepanywhere-relay = {
    enable = true;
    port = 4400;
  };

  # Caddy with automatic HTTPS (Let's Encrypt)
  services.caddy.virtualHosts.${yepRelayDomain} = {
    extraConfig = ''
      # Structured access logging for fail2ban
      log {
        output file /var/log/caddy/yep-access.log
        format json
      }

      # Config endpoint for relay discovery
      handle /api/config {
        header Content-Type application/json
        respond `{"relay":{"servers":[{"url":"wss://${yepRelayDomain}","region":"us"}],"minVersion":"0.3.0","maxVersion":null}}` 200
      }

      # Block relay endpoints that leak connection info
      handle /status {
        respond 404
      }
      handle /online/* {
        respond 404
      }

      # WebSocket traffic goes to the relay
      @websocket {
        header Connection *Upgrade*
        header Upgrade websocket
      }
      handle @websocket {
        rewrite / /ws
        reverse_proxy localhost:${internalPort}
      }

      # Relay API endpoints
      handle /ws {
        reverse_proxy localhost:${internalPort}
      }

      # Serve remote client UI at /remote (where the frontend expects it)
      handle_path /remote/* {
        root * ${yepanywhere-remote}
        file_server
        try_files {path} /remote.html
      }

      # Redirect root to /remote
      handle {
        redir / /remote/ permanent
      }
    '';
  };

  # fail2ban for rate limiting repeated WebSocket connection attempts
  services.fail2ban = {
    enable = true;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      maxtime = "24h";
    };
    jails = {
      yep-relay = {
        settings = {
          enabled = true;
          filter = "yep-relay";
          backend = "auto";
          logpath = "/var/log/caddy/yep-access.log";
          maxretry = 20;
          findtime = 60;
          bantime = 3600;
        };
      };
    };
  };

  # fail2ban filter: match rapid WebSocket upgrade requests
  environment.etc."fail2ban/filter.d/yep-relay.conf".text = ''
    [Definition]
    failregex = ^.*"request":\{[^}]*"client_ip":"<HOST>".*"uri":"/ws".*$
    ignoreregex =
  '';

  # Ensure log directory exists
  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0755 caddy caddy -"
  ];

  # Open ports for HTTPS and ACME challenge
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
