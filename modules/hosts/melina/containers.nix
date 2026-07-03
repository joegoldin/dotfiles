# Home Assistant, run as a Docker container via oci-containers — faithfully
# reproducing the mini-ubuntu setup (from `docker inspect`). Its state is
# restored from the Ubuntu box into /var/lib/homeassistant. Host networking +
# privileged (device / Bluetooth / discovery access). Homebridge was NOT
# migrated (backup was lost; not needed).
_: {
  den.aspects.melina.nixos = _: {
    # Data dir HA bind-mounts (restored from the Ubuntu backup). Container procs
    # run as root, so files are root-owned.
    systemd.tmpfiles.rules = [
      "d /var/lib/homeassistant 0750 root root -"
    ];

    virtualisation.oci-containers = {
      backend = "docker";
      # was: /home/joe/homeassistant/config:/config + /run/dbus:/run/dbus:ro,
      # --network host, --privileged, --security-opt label=disable
      containers.homeassistant = {
        image = "ghcr.io/home-assistant/home-assistant:stable";
        autoStart = true;
        environment.TZ = "America/Los_Angeles";
        volumes = [
          "/var/lib/homeassistant:/config"
          "/run/dbus:/run/dbus:ro"
        ];
        extraOptions = [
          "--network=host"
          "--privileged"
          "--security-opt=label=disable"
          # habluetooth needs these even under --privileged on some setups
          "--cap-add=NET_ADMIN"
          "--cap-add=NET_RAW"
        ];
      };
    };

    # HA uses host networking, so its ports are on the host — open the UI + the
    # local discovery traffic HA relies on.
    networking.firewall = {
      allowedTCPPorts = [ 8123 ]; # Home Assistant
      allowedUDPPorts = [
        5353 # mDNS (local device discovery)
        1900 # SSDP (UPnP/DLNA discovery)
      ];
    };
  };
}
