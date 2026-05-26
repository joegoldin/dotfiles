# common/default.nix
{ inputs, ... }:
{
  imports = [
    ../common/system/attic.nix
    ../common/system/numtide-cache.nix
    ./hardware-configuration.nix

    inputs.nixos-wsl.nixosModules.default
    ./wsl.nix
  ];
}
