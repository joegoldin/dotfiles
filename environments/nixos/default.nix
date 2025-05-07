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

  services.wallpaper = {
    enable = true;
    wallpaperDir = "${config.users.users.${username}.home}/Pictures/Wallpaper";
    monitorMapping = {
      "DP-3" = 0;
      "DP-2" = 2;
      "HDMI-A-1" = 3;
      "DP-1" = 1;
      "DVI-I-2" = 4;
      "DVI-I-1" = 5;
    };
  };
}
