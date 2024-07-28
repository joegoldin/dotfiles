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
    ../nixos/configuration.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./oracle-cloud.nix
  ];
}
