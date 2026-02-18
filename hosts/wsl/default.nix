# common/default.nix
{ inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix

    inputs.nixos-wsl.nixosModules.default
    ./wsl.nix
  ];
}
