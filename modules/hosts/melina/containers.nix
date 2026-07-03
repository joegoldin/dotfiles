# Home Assistant + Homebridge, run as Docker containers via oci-containers —
# faithfully reproducing the mini-ubuntu setup (from `docker inspect`). Their
# state is restored from the Ubuntu box into /var/lib/{homeassistant,homebridge}
# (see the migration plan). Both use host networking; Homebridge keeps its own
# in-container avahi for HomeKit mDNS, so the host avahi stays off.
_: {
  den.aspects.melina.nixos = _: {
    # Data dirs the containers bind-mount (restored from the Ubuntu backup).
    # Container processes run as root, so files are root-owned.
    systemd.tmpfiles.rules = [
      "d /var/lib/homeassistant 0750 root root -"
      "d /var/lib/homebridge 0750 root root -"
    ];

    virtualisation.oci-containers = {
      backend = "docker";
      containers = {
        # was: /home/joe/homeassistant/config:/config + /run/dbus:/run/dbus:ro,
        # --network host, --privileged, --security-opt label=disable
        homeassistant = {
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

        # was: /home/joe/homebridge/volumes/homebridge:/homebridge, --network host
        homebridge = {
          image = "homebridge/homebridge:latest";
          autoStart = true;
          environment.ENABLE_AVAHI = "1";
          volumes = [ "/var/lib/homebridge:/homebridge" ];
          extraOptions = [
            "--network=host"
            "--log-opt=max-size=10m"
            "--log-opt=max-file=1"
          ];
        };
      };
    };

    # The containers use host networking, so their ports are on the host —
    # open the web UIs + the discovery/HomeKit traffic. (LAN box behind the
    # router; if HomeKit pairing needs more, trust the LAN iface enp1s0.)
    networking.firewall = {
      allowedTCPPorts = [
        8123 # Home Assistant
        8581 # Homebridge UI
        21063 # HA HomeKit integration bridge (if used)
        51826 # Homebridge HomeKit bridge (default)
      ];
      allowedUDPPorts = [
        5353 # mDNS (HomeKit + local discovery)
        1900 # SSDP (UPnP/DLNA discovery)
      ];
    };
  };
}
