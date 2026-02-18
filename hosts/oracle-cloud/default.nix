# common/default.nix
{ ... }:
{
  imports = [
    ./configuration.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./oracle-cloud.nix
    ./pelican.nix
  ];
}
