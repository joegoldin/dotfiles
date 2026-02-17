{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  scriptPath = "${config.users.users.${username}.home}/dotfiles/scripts/set-wallpaper.py";
  wallpaperDirs = [
    "${config.users.users.${username}.home}/Pictures/Wallpaper"
    "${config.users.users.${username}.home}/Pictures/Backgrounds"
  ];
  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.dbus-python
    ps.pillow
  ]);
in
{
  systemd.user.timers."set-wallpaper" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "60m";
      OnUnitActiveSec = "60m";
      Unit = "set-wallpaper.service";
    };
  };

  systemd.user.services."set-wallpaper" = {
    script = ''
      ${pythonEnv}/bin/python3 ${scriptPath} ${lib.concatStringsSep " " wallpaperDirs}
    '';
    path = [ pkgs.xorg.xrandr ];
    serviceConfig = {
      Type = "oneshot";
    };
  };
}
