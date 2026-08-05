# Logitech Litra lights: hidraw access rules, the `litra` CLI, and the
# litra-autotoggle daemon that turns the lights on with the Elgato Facecam.
{ ... }:
{
  den.aspects.elphael.nixos =
    { lib, pkgs, ... }:
    let
      # litra-autotoggle resolves the by-id symlink at startup (see the patch
      # on the package) and watches /dev for that node's events.
      facecam = import ./_facecam.nix { inherit lib pkgs; };

      # Only the video device is pinned. With no device filter, every attached
      # Litra follows the camera (currently the Glow and the Beam LX front
      # light; add `back = true;` to also drive the Beam LX's backlight).
      configFile = (pkgs.formats.yaml { }).generate "litra-autotoggle.yml" {
        video_device = facecam.path;
        # Apps open and close the node a few times while starting a call, and
        # something on this box probes every /dev/video* node ~2x a second.
        # 1500ms is the upstream default and rides out both.
        delay = 1500;
      };

    in
    {
      environment.systemPackages = [ pkgs.litra ];

      services.udev.packages = [
        # 99-litra.rules from upstream: GROUP="video" on the Litra hidraw
        # nodes, so both the CLI and the daemon work without root.
        pkgs.litra
        (facecam.restartOnReplug "litra-autotoggle.service")
      ];

      systemd.services.litra-autotoggle = {
        description = "Turn the Litra lights on and off with the Elgato Facecam";
        documentation = [ "https://github.com/timrogers/litra-autotoggle" ];
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-udevd.service" ];

        serviceConfig = {
          Type = "simple";

          # If the camera never turns up, start anyway — the udev rule above
          # restarts the unit when it does appear.
          ExecStartPre = facecam.waitForDevice;
          ExecStart = "${lib.getExe pkgs.litra-autotoggle} --config-file ${configFile}";
          Restart = "always";
          RestartSec = 5;

          # Nix owns the version; skip the daily check against the GitHub API.
          Environment = [ "LITRA_AUTOTOGGLE_DISABLE_UPDATE_CHECK=1" ];

          # Watches /dev and writes HID reports to the Litras — the `video`
          # group (via 99-litra.rules) is the only privilege it needs.
          DynamicUser = true;
          SupplementaryGroups = [ "video" ];

          PrivateNetwork = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [ "@system-service" ];

          # Every camera open is an INFO line, and that background probing
          # adds up — keep it from drowning the journal.
          LogRateLimitIntervalSec = 30;
          LogRateLimitBurst = 100;
        };
      };
    };
}
