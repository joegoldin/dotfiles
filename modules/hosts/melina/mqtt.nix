# Mosquitto (native NixOS service, not a container — well-packaged in
# nixpkgs and simple enough not to need one). Broker for HA's MQTT
# integration and any LAN devices that publish over MQTT directly
# (ESPHome, Tasmota, etc.), alongside the Zigbee/Thread/Matter stacks in
# the sibling files.
{ inputs, ... }:
{
  den.aspects.melina.nixos =
    { config, ... }:
    {
      age.secrets.mosquitto-homeassistant-password.file = "${inputs.dotfiles-secrets}/mosquitto-homeassistant-password.age";

      services.mosquitto = {
        enable = true;
        listeners = [
          {
            port = 1883;
            users.homeassistant = {
              acl = [ "readwrite #" ];
              passwordFile = config.age.secrets.mosquitto-homeassistant-password.path;
            };
          }
        ];
      };

      networking.firewall.allowedTCPPorts = [ 1883 ]; # MQTT
    };
}
