{ ... }:
{
  imports = [
    ./cloud-proxy.nix
    ./configuration.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./services.nix
  ];
}
