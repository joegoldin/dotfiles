{ ... }:
let
  meta = import ../../_lib/meta.nix;
  username = meta.username;
in
{
  den.aspects.joe-desktop.nixos =
    {
      config,
      lib,
      pkgs,
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
      systemd.user = {
        timers."set-wallpaper" = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "60m";
            OnUnitActiveSec = "60m";
            Unit = "set-wallpaper.service";
          };
        };

        services = {
          "set-wallpaper" = {
            script = ''
              ${pythonEnv}/bin/python3 ${scriptPath} ${lib.concatStringsSep " " wallpaperDirs}
            '';
            path = [ pkgs.xrandr ];
            serviceConfig = {
              Type = "oneshot";
            };
          };

          # Re-apply the wallpaper a few seconds after the Plasma shell starts, so a
          # fresh spanned image lands on every login/boot and after the plasmashell
          # restart that `nixos-rebuild` triggers. The slices set-wallpaper.py writes
          # live in /tmp (wiped on reboot), so the persisted wallpaper paths would
          # otherwise be dangling until the hourly timer fires.
          #
          # WantedBy pulls this oneshot in whenever plasma-plasmashell.service starts
          # (including restarts); the ExecStartPre delay gives plasmashell's DBus
          # interface time to come up before set-wallpaper.py calls evaluateScript.
          # It only triggers set-wallpaper.service rather than duplicating the work,
          # so the manual `rotate-wallpaper` and hourly timer paths stay delay-free.
          "set-wallpaper-after-plasma" = {
            description = "Rotate wallpaper shortly after the Plasma shell starts";
            after = [ "plasma-plasmashell.service" ];
            wantedBy = [ "plasma-plasmashell.service" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
              ExecStart = "${pkgs.systemd}/bin/systemctl --user start set-wallpaper.service";
            };
          };
        };
      };
    };
}
