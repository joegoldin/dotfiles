# common/default.nix
{ ... }:
{
  imports = [
    ./attic.nix
    ./configuration.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./racknerd-cloud.nix
    ./services.nix
  ];
}
