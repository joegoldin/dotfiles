# common/default.nix
{ ... }:
{
  imports = [
    ./attic.nix
    ./configuration.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./oracle-cloud.nix
    ./pelican.nix
  ];
}
