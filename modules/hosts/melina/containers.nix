# Docker containers (via oci-containers): Home Assistant (migrated from the
# mini-ubuntu box, state in /var/lib/homeassistant) + byob-bot (a Discord bot,
# tokens supplied from an agenix-encrypted env file).
{ inputs, ... }:
{
  den.aspects.melina.nixos =
    { config, ... }:
    let
      # SONOFF Dongle Plus MG24 (Zigbee coordinator, stock EmberZNet firmware).
      # Pinned by-id, never /dev/ttyUSB0: the bare name renumbers on reboot or
      # when a second USB-serial device appears — and a second one is planned
      # (a Thread/OpenThread stick), so ttyUSB0 would become ambiguous.
      zigbeeDongle =
        "/dev/serial/by-id/usb-SONOFF_SONOFF_Dongle_Plus_MG24_1eda3ba1c0f5ef118b9697a29ed47d52-if00-port0";
    in
    {
      # Data dir HA bind-mounts (restored from the Ubuntu backup). Container procs
      # run as root, so files are root-owned.
      systemd.tmpfiles.rules = [
        "d /var/lib/homeassistant 0750 root root -"
      ];

      # byob-bot's env file (DISCORD_TOKEN, YTAPIKEY), agenix-encrypted.
      age.secrets.byob-bot-env.file = "${inputs.dotfiles-secrets}/byob-bot.env.age";

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
              # ha-compose, mounted read-only straight from the store rather than
              # installed via HACS, so an update can't silently overwrite it. The
              # store path changes on every bump, which restarts the container —
              # that's the intended reload.
              "${inputs.ha-compose}/custom_components/ha_compose:/config/custom_components/ha_compose:ro"
              "/run/dbus:/run/dbus:ro"
              # HA's USB discovery goes through pyudev, which needs the host's
              # udev runtime. Without this, `hardware/info` returns an empty list
              # and a plugged-in Zigbee stick is never offered as a discovery
              # flow — verified on this host before adding it.
              "/run/udev:/run/udev:ro"
            ];
            extraOptions = [
              "--network=host"
              "--privileged"
              "--security-opt=label=disable"
              # habluetooth needs these even under --privileged on some setups
              "--cap-add=NET_ADMIN"
              "--cap-add=NET_RAW"
              # Required, not merely documentation: --privileged lifts the device
              # cgroup restriction but the container still gets its own minimal
              # /dev, so the host's ttyUSB0 and by-id symlinks are genuinely
              # absent until passed explicitly (checked with docker exec).
              # Trade-off: the container will not start if the dongle is
              # unplugged. That is preferable to ZHA silently losing its radio.
              "--device=${zigbeeDongle}"
            ];
          };

          # github.com/joegoldin/byob-discord-bot, built + published to ghcr.
          # `docker run -d --env-file byob-bot.env <image>`
          byob-bot = {
            image = "ghcr.io/joegoldin/byob-discord-bot:latest";
            autoStart = true;
            environmentFiles = [ config.age.secrets.byob-bot-env.path ];
          };
        };
      };

      # byob-bot needs its env secret decrypted (agenix) before it starts.
      systemd.services.docker-byob-bot = {
        after = [ "agenix.service" ];
        wants = [ "agenix.service" ];
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
