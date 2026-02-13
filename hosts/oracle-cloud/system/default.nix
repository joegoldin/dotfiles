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
    ./configuration.nix
    ./disk-config.nix
    ./hardware-configuration.nix
    ./oracle-cloud.nix
    ./pelican.nix
  ];
}
