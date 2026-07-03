# Docker containers (via oci-containers): Home Assistant (migrated from the
# mini-ubuntu box, state in /var/lib/homeassistant) + byob-bot (a Discord bot,
# tokens supplied from an agenix-encrypted env file).
{ inputs, ... }:
{
  den.aspects.melina.nixos =
    { config, ... }:
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
