# Tailscale Serve endpoints; both backends listen on loopback only.
inputs:
let
  domains = import "${inputs.dotfiles-secrets}/domains.nix";
  endpoint =
    url:
    let
      parts = builtins.match "https://([^/:]+):([0-9]+)" url;
    in
    assert parts != null;
    {
      host = builtins.elemAt parts 0;
      port = builtins.elemAt parts 1;
    };
  celler = endpoint domains.cellerUrl;
  hydra = endpoint domains.hydraUrl;
in
{
  cellerHost = celler.host;
  cellerAuthority = "${celler.host}:${celler.port}";
  cellerPort = celler.port;
  cellerURL = domains.cellerUrl;
  hydraPort = hydra.port;
  hydraURL = domains.hydraUrl;
  armBuilder = domains.hydraArmBuilderHost;
  cellerNetrc = "/run/celler-netrc";

  # Foreground Serve is tied to the service lifetime and does not leave behind
  # a persistent listener. Do not use Funnel for either service.
  serve =
    {
      config,
      backend,
      port,
      unit,
    }:
    {
      description = "Expose ${unit} on the tailnet only";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
        "tailscaled.service"
        "${unit}.service"
      ];
      requires = [ "tailscaled.service" ];
      partOf = [ "tailscaled.service" ];
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig = {
        ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --yes --https=${port} ${backend}";
        Restart = "always";
        RestartSec = "10s";
      };
    };
}
