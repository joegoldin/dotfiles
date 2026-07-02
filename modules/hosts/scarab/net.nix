# Connectivity: Tailscale (client) + mDNS + onboard WiFi via wpa_supplicant.
#
# WiFi: the agenix-decrypted secret is a full wpa_supplicant.conf with a
# `network={…}` block (SSID + PSK both encrypted). NixOS's wireless module, when
# `networks` is empty, launches wpa_supplicant with `-c …/imperative.conf` (an
# empty managed file) and does NOT read /etc/wpa_supplicant.conf — so we feed our
# conf via `extraConfigFiles`, which the module appends as `-I <path>`. With
# hardening on (default), wpa_supplicant runs as the `wpa_supplicant` user, so
# the secret must be owned by it to be readable.
{ inputs, ... }:
{
  den.aspects.scarab.nixos =
    { config, ... }:
    {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };
      # Tailscale MagicDNS needs systemd-resolved.
      services.resolved.enable = true;

      # mDNS so `crawler.local` resolves on the LAN (no router-snooping, no
      # tailscale needed for first contact).
      services.avahi = {
        enable = true;
        openFirewall = true;
        publish = {
          enable = true;
          addresses = true;
          workstation = true;
        };
      };

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
        trustedInterfaces = [ "tailscale0" ];
      };

      networking.wireless = {
        enable = true;
        extraConfigFiles = [ config.age.secrets.crawler-wlan.path ];
      };
      age.secrets.crawler-wlan = {
        file = "${inputs.dotfiles-secrets}/crawler-wlan.age";
        owner = "wpa_supplicant";
        mode = "0400";
      };
    };
}
