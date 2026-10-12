# punktfunk (git.unom.io/unom/punktfunk), the game-streaming host and client.
#
# Hosts include one of:
#   punktfunk-client        native GTK client
#   punktfunk-host          streaming host reachable from the LAN and the tailnet
#   punktfunk-host-tailnet  streaming host reachable from the tailnet only
#
# Each includes the base `punktfunk` aspect, which owns the upstream module
# import. That import is `import ./nixos-module.nix self`, an anonymous function
# the module system cannot deduplicate, so a machine that is both host and
# client must get it from exactly one place or its options are declared twice.
{ den, inputs, ... }:
let
  meta = import ../_lib/meta.nix;

  # Shared by both host variants; they differ only in firewall exposure.
  host = {
    enable = true;
    users = [ meta.username ];
    autoStart = true;
    # Restart the host with the Plasma session so it never holds a dead
    # compositor/portal connection after a logout or KWin restart.
    desktopSession = true;
  };
in
{
  den.aspects.punktfunk.nixos = {
    imports = [ inputs.punktfunk.nixosModules.default ];

    # CI publishes only punktfunk's own store paths here; without it the host
    # and client compile the whole Rust workspace from source.
    nix.settings = {
      extra-substituters = [ "https://nix.unom.io" ];
      extra-trusted-public-keys = [
        "punktfunk-cache-1:yhOJmHxzg6tzXpxSFzlYn6Pc6r0jHprsWqt8MZC654o="
      ];
    };
  };

  # The upstream module's client half installs the GTK client and raises the
  # UDP receive-buffer ceiling; openFirewall opens mDNS so hosts on the LAN are
  # discovered without typing an address.
  den.aspects.punktfunk-client = {
    includes = [ den.aspects.punktfunk ];
    nixos.services.punktfunk.client = {
      enable = true;
      openFirewall = true;
    };
  };

  # upstream openFirewall opens the native ports, mDNS and the web console on
  # every interface, which covers the tailnet as well as the LAN.
  den.aspects.punktfunk-host = {
    includes = [ den.aspects.punktfunk ];
    nixos.services.punktfunk.host = host // {
      openFirewall = true;
    };
  };

  # Upstream openFirewall stays off (it is global) and the native ports open on
  # tailscale0 alone. mDNS is left out because it does not cross the tailnet;
  # clients connect by MagicDNS name or 100.x address. The per-session media
  # port is ephemeral and hole-punched by the host, so the default-deny
  # firewall still streams, at the cost of ~2.5 s at session start.
  den.aspects.punktfunk-host-tailnet = {
    includes = [ den.aspects.punktfunk ];
    nixos = {
      services.punktfunk.host = host;

      networking.firewall.interfaces."tailscale0" = {
        allowedTCPPorts = [
          47990 # mgmt/library API (HTTPS + mTLS)
          47992 # web console
          47993 # web console plugin-UI origin
        ];
        allowedUDPPorts = [
          9777 # QUIC control plane
          9778 # browser streaming
        ];
      };
    };
  };
}
