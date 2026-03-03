# common/default.nix
{ ... }:
{
  imports = [
    ../common/system/attic-substituter.nix
    ./attic.nix
    ./configuration.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./oracle-cloud.nix
    ./pelican.nix
  ];
}
