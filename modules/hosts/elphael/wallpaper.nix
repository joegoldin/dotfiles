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
              ${scriptPath} ${lib.concatStringsSep " " wallpaperDirs}
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
