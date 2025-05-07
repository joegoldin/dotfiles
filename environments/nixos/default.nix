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
    ./hardware-configuration.nix
    ./joe-desktop.nix
    ./wallpaper.nix
  ];
}
