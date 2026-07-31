# OpenThread Border Router (via oci-containers), bridging the second USB radio
# to Home Assistant's Thread integration. HA has no OTBR of its own outside
# HAOS/Supervisor, so it discovers this container over mDNS instead.
{ ... }:
{
  den.aspects.melina.nixos =
    { ... }:
    let
      # Inswift ZBM-MG21 (EFR32MG21 + WCH CH9102 bridge) — same reference design
      # as the Sonoff ZBDongle-E. Flashed from stock EmberZNet to OpenThread RCP
      # firmware (darkxst/silabs-firmware-builder, zbdonglee_openthread_rcp,
      # 460800 baud, no flow control). Pinned by-id: distinct device from the
      # Zigbee coordinator's /dev/ttyUSB0 in containers.nix.
      threadDongle = "/dev/serial/by-id/usb-1a86_USB_Single_Serial_5A5B007535-if00";
    in
    {
      # Thread network credentials/state, persisted across container restarts.
      systemd.tmpfiles.rules = [
        "d /var/lib/otbr 0750 root root -"
      ];

      virtualisation.oci-containers.containers.otbr = {
        image = "openthread/border-router:latest";
        autoStart = true;
        environment = {
          OT_RCP_DEVICE = "spinel+hdlc+uart://${threadDongle}?uart-baudrate=460800";
          OT_INFRA_IF = "enp1s0"; # LAN backbone interface (see machine.nix)
        };
        volumes = [ "/var/lib/otbr:/data" ];
        extraOptions = [
          "--network=host"
          "--cap-add=NET_ADMIN"
          "--cap-add=NET_RAW"
          # wpan0, the Thread mesh's tunnel interface, is created here.
          "--device=/dev/net/tun"
          "--device=${threadDongle}"
        ];
      };

      # otbr-agent's REST API binds 127.0.0.1:8081 by default; since both
      # containers use --network=host they share loopback, so HA reaches it
      # without a published port. mDNS (5353/udp, for HA to discover this
      # border router) is already open in containers.nix.
    };
}
