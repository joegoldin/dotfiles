# Logitech Litra lights: hidraw access rules, the `litra` CLI, and a daemon
# that turns the lights on with the Elgato Facecam.
#
# Upstream litra-autotoggle is not used on purpose: its Linux backend counts
# inotify open/close events, and with Zoom probing the node twice a second the
# counter drifts (dropped events) until it sticks above zero and the lights
# turn on forever. The camera's USB traffic is watched instead — see
# watchStreaming in ./_facecam.nix.
{ ... }:
{
  den.aspects.elphael.nixos =
    { lib, pkgs, ... }:
    let
      facecam = import ./_facecam.nix { inherit lib pkgs; };

      # `litra on`/`off` target every attached device by default (currently
      # the Glow and the Beam LX front light; the Beam LX backlight is only
      # reachable through the separate back-* subcommands and stays manual).
      # A failed HID write is logged and left for the next transition; the
      # lights being briefly wrong is not worth killing the watcher over.
      litra-follow-facecam = pkgs.writeShellApplication {
        name = "litra-follow-facecam";
        runtimeInputs = [ pkgs.litra ];
        text = ''
          ${lib.getExe' facecam.watchStreaming "facecam-watch-streaming"} \
            | while read -r state; do
                echo "camera $state: turning the lights $state"
                litra "$state" || echo "warning: litra $state failed" >&2
              done
        '';
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
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-udevd.service" ];

        serviceConfig = {
          Type = "simple";

          # If the camera never turns up, start anyway — the udev rule above
          # restarts the unit when it does appear.
          ExecStartPre = facecam.waitForDevice;
          ExecStart = lib.getExe litra-follow-facecam;
          Restart = "always";
          RestartSec = 5;

          # Reads sysfs and writes HID reports to the Litras — the `video`
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
        };
      };
    };
}
