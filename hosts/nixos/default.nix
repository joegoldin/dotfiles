# common/default.nix
{
  lib,
  inputs,
  outputs,
  config,
  username,
  hostname,
  stateVersion,
  ...
}: {
  imports = [
    ./configuration.nix
    ./hardware-configuration.nix
    ./drag-shift.nix
    ./gaming.nix
    ./joe-desktop.nix
    ./wallpaper.nix
  ];
}
