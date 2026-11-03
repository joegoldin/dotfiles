# Host-specific home config that isn't plasma (see ./plasma.nix for that):
# flatpaks, android tooling, desktop packages, python extras, dolphin places.
{ inputs, ... }:
{
  den.aspects.elphael.homeManager = {
    imports = [
      inputs.nix-flatpak.homeManagerModules.nix-flatpak
      ./_android.nix
      ./_packages
      ./_python.nix
      ./_dolphin.nix
    ];
  };
}
