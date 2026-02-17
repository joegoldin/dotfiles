# common/default.nix
{
  ...
}:
{
  imports = [
    ./configuration.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./racknerd-cloud.nix
    ./services.nix
  ];
}
