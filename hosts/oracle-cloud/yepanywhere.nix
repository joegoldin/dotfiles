# YepAnywhere relay server on bastion with Caddy HTTPS
{
  dotfiles-secrets,
  ...
}:
let
  domains = import "${dotfiles-secrets}/domains.nix";
  yepRelayDomain = domains.yepRelayDomain;
  internalPort = "4400";
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

      # Rewrite root WebSocket upgrades to /ws for the relay
      @websocket_root {
        path /
        header Connection *Upgrade*
        header Upgrade websocket
      }
      rewrite @websocket_root /ws

      # Proxy everything to the relay server
      reverse_proxy localhost:${internalPort}
    '';
  };

  # Open ports for HTTPS and ACME challenge
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
