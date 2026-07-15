# Melina — home-automation host (formerly the mini-ubuntu box: Ryzen 7 5700U,
# single 954 GB NVMe). Runs Home Assistant as a Docker container (state restored
# from the Ubuntu box's config dir into /var/lib/homeassistant). Entity name
# (= flake output) and hostName are both "melina". Installed via nixos-anywhere;
# lean home like rennala. agenix holds byob-bot's env secret (Discord/YouTube
# tokens); tailscale is brought up manually. Aspect content lives in the sibling
# files (system.nix, machine.nix, containers.nix, home.nix).
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.hosts.x86_64-linux.melina = {
    hostName = "melina";
    users.${meta.username} = { };
  };

  den.aspects.melina = {
    includes = [
      den.aspects.nix-settings
    ];

    nixos = {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.agenix.nixosModules.default
        ./_disk-config.nix
        ./_hardware-configuration.nix
      ];

      # Decrypt agenix secrets with melina's own SSH host key (add it to
      # keys.nix + `systems` and rekey after install).
      age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };
}
