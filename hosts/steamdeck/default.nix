# hosts/steamdeck/default.nix
{ ... }:
{
  imports = [
    ../common/system/attic.nix
    ../common/system/gaming.nix
    ./configuration.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./jovian.nix
  ];
}
