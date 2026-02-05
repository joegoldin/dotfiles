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
    ./racknerd-cloud.nix
    ./services.nix
  ];
}
