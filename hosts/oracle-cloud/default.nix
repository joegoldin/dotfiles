# common/default.nix
{ ... }:
{
  imports = [
    ../common/system/attic.nix
    ../common/system/numtide-cache.nix
    ./configuration.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./oracle-cloud.nix
    ./pelican.nix
    ./yepanywhere.nix
  ];
}
