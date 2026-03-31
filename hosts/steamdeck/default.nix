# hosts/steamdeck/default.nix
{ ... }:
{
  imports = [
    ../common/system/attic.nix
    ../common/system/gaming.nix
    ./configuration.nix
    ./hardware-configuration.nix
    ./jovian.nix
  ];
}
