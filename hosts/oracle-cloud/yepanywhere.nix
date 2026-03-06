# YepAnywhere relay server on bastion (behind Cloudflare tunnel)
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

  # Caddy reverse proxy + config endpoint
  services.caddy.virtualHosts."http://${yepRelayDomain}" = {
    extraConfig = ''
      # Config endpoint for relay discovery
      handle /api/config {
        header Content-Type application/json
        respond `{"relay":{"servers":[{"url":"wss://${yepRelayDomain}","region":"us"}],"minVersion":"0.3.0","maxVersion":null}}` 200
      }

      # Proxy everything else to the relay server
      reverse_proxy localhost:${internalPort}
    '';
  };
}
