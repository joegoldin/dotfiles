# common/default.nix
{
  lib,
  inputs,
  outputs,
  pkgs,
  config,
  username,
  hostname,
  stateVersion,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    inputs.nixos-wsl.nixosModules.default
    ./wsl.nix
  ];
}
