# common/default.nix
{ inputs, ... }:
{
  imports = [
    ../common/system/attic-substituter.nix
    ./hardware-configuration.nix

    inputs.nixos-wsl.nixosModules.default
    ./wsl.nix
  ];
}
