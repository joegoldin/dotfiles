# python-matter-server (via oci-containers): a standalone Matter controller
# over WebSocket, since Home Assistant here runs as a plain Docker container
# and has no Supervisor to install the official Matter add-on. Point HA's
# Matter integration at ws://localhost:5580/ws (loopback, shared via
# --network=host — same reasoning as the OTBR/HA split in thread.nix).
{ ... }:
{
  den.aspects.melina.nixos =
    { ... }:
    {
      # Matter fabric/commissioning data, persisted across container restarts.
      systemd.tmpfiles.rules = [
        "d /var/lib/matter-server 0750 root root -"
      ];

      virtualisation.oci-containers.containers.matter-server = {
        # home-assistant-libs/python-matter-server moved to the matter-js org.
        # Upstream's README now points at matterjs-server (a matter.js rewrite)
        # but it's still beta and doesn't fully support Thread commissioning yet
        # ("requires a network Name which is not provided") — stick with the
        # "final" stable Python server for now, since Thread is exactly what
        # thread.nix's OTBR was set up for.
        image = "ghcr.io/matter-js/python-matter-server:stable";
        autoStart = true;
        volumes = [
          "/var/lib/matter-server:/data"
          # BLE commissioning talks to the host's BlueZ over D-Bus — same
          # mount HA's own Bluetooth integration uses in containers.nix.
          "/run/dbus:/run/dbus:ro"
        ];
        extraOptions = [
          "--network=host" # required for mDNS
          "--security-opt=apparmor=unconfined" # needed for Bluetooth via dbus
        ];
      };

      # 5540/udp is the Matter operational port devices use to reach this
      # controller (mDNS/5353 is already open in containers.nix). 5580/tcp is
      # the server's own WebSocket + dashboard — HA reaches it over loopback
      # since both containers use --network=host, but open it on the LAN too
      # for the dashboard (commissioning/debugging individual nodes).
      networking.firewall = {
        allowedTCPPorts = [ 5580 ];
        allowedUDPPorts = [ 5540 ];
      };
    };
}
