# common/default.nix
{ ... }:
{
  imports = [
    ../common/system/attic.nix
    ./attic.nix
    ./configuration.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./racknerd-cloud.nix
    ./services.nix
  ];
}
