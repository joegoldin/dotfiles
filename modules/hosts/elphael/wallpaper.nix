{ ... }:
let
  meta = import ../../_lib/meta.nix;
  username = meta.username;
in
{
  den.aspects.elphael.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # the set-wallpaper bins script (modules/home/bin/_scripts/set-wallpaper.nix)
      # from joe's home profile
      scriptPath = "/etc/profiles/per-user/${username}/bin/set-wallpaper";
      wallpaperDirs = [
        "${config.users.users.${username}.home}/Pictures/Wallpaper"
        "${config.users.users.${username}.home}/Pictures/Backgrounds"
      ];
      # An unreachable screensaver interface counts as unlocked: a rotation that
      # skips is recoverable, one that can never run again is not.
      sessionUnlocked = pkgs.writeShellApplication {
        name = "session-unlocked";
        runtimeInputs = [ pkgs.systemd ];
        text = ''
          state=$(busctl --user call org.freedesktop.ScreenSaver /ScreenSaver \
            org.freedesktop.ScreenSaver GetActive 2>/dev/null || true)

          if [ "$state" = "b true" ]; then
            echo "Session is locked; skipping wallpaper rotation"
            exit 1
          fi
        '';
      };
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
          # Skipped while the session is locked. With every output DPMS'd off,
          # plasmashell stops answering DBus, so evaluateScript times out and the
          # run dies after it has already written slices Plasma never adopts. The
          # hourly timer picks the rotation back up once the session returns.
          "set-wallpaper" = {
            script = ''
              ${scriptPath} ${lib.concatStringsSep " " wallpaperDirs}
            '';
            path = [ pkgs.xrandr ];
            serviceConfig = {
              Type = "oneshot";
              ExecCondition = lib.getExe sessionUnlocked;
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
