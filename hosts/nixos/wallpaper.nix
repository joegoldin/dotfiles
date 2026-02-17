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
  inherit (config.users.users.${username}) uid;
in
{
  systemd.timers."set-wallpaper" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "60m";
      OnUnitActiveSec = "60m";
      Unit = "set-wallpaper.service";
    };
  };

  systemd.services."set-wallpaper" = {
    script = ''
      set -eu

      # Create a temporary .Xauthority file
      XAUTH_TMP=$(mktemp)

      # Find and copy the most recent xauth file
      XAUTH_FILE=$(ls -t /run/user/${toString uid}/xauth_* 2>/dev/null | head -n1)
      if [ -n "$XAUTH_FILE" ]; then
        cp "$XAUTH_FILE" "$XAUTH_TMP"
      else
        echo "No xauth file found"
        exit 1
      fi

      export XAUTHORITY="$XAUTH_TMP"

      ${
        pkgs.python3.withPackages (ps: [
          ps.dbus-python
          ps.pillow
        ])
      }/bin/python3 ${scriptPath} ${lib.concatStringsSep " " wallpaperDirs}

      # Clean up
      rm -f "$XAUTH_TMP"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = username;
      Environment = [
        "DISPLAY=:0"
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${toString uid}/bus"
        "PATH=${pkgs.xorg.xrandr}/bin:${pkgs.coreutils}/bin:${pkgs.xorg.xauth}/bin"
      ];
    };
  };
}
