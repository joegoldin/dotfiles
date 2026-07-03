# Melina — home-automation host (formerly the mini-ubuntu box: Ryzen 7 5700U,
# single 954 GB NVMe). Runs Home Assistant as a Docker container (state restored
# from the Ubuntu box's config dir into /var/lib/homeassistant). Entity name
# (= flake output) and hostName are both "melina". Installed via nixos-anywhere;
# lean home like rennala. No agenix secrets (the containers' state lives in
# /var/lib, tailscale is brought up manually). Aspect content lives in the
# sibling files (system.nix, machine.nix, containers.nix, home.nix).
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

    nixos.imports = [
      inputs.disko.nixosModules.disko
      inputs.nix-index-database.nixosModules.default
      ./_disk-config.nix
      ./_hardware-configuration.nix
    ];
  };
}
