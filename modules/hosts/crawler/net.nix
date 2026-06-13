# Connectivity: Tailscale (client) + onboard WiFi via wpa_supplicant. The whole
# wpa_supplicant.conf is supplied by agenix at /etc/wpa_supplicant.conf, so both
# SSID and PSK stay encrypted. networking.wireless.networks is left unset, so
# the module runs wpa_supplicant against /etc/wpa_supplicant.conf directly
# (per the NixOS option docs).
{ inputs, ... }:
{
  den.aspects.crawler.nixos = {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };
    # Tailscale MagicDNS needs systemd-resolved.
    services.resolved.enable = true;

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      trustedInterfaces = [ "tailscale0" ];
    };

    # networks intentionally unset -> wpa_supplicant uses /etc/wpa_supplicant.conf
    networking.wireless.enable = true;

    age.secrets.crawler-wlan = {
      file = "${inputs.dotfiles-secrets}/crawler-wlan.age";
      path = "/etc/wpa_supplicant.conf";
      mode = "0400";
    };
  };
}
