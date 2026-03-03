# common/default.nix
{ ... }:
{
  imports = [
    ../common/system/attic-substituter.nix
    ./configuration.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./racknerd-cloud.nix
    ./services.nix
  ];
}
