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
      # Config endpoint for relay discovery
      handle /api/config {
        header Content-Type application/json
        respond `{"relay":{"servers":[{"url":"wss://${yepRelayDomain}","region":"us"}],"minVersion":"0.3.0","maxVersion":null}}` 200
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

      # Everything else serves the remote client UI
      handle {
        root * ${yepanywhere-remote}
        file_server
        try_files {path} /remote.html
      }
    '';
  };

  # Open ports for HTTPS and ACME challenge
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
