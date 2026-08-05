# Logitech Litra lights: hidraw access rules, the `litra` CLI, and the
# litra-autotoggle daemon that turns the lights on with the Elgato Facecam.
{ ... }:
{
  den.aspects.elphael.nixos =
    { lib, pkgs, ... }:
    let
      # The Facecam's capture node. /dev/videoN is handed out in probe order
      # and moves when USB devices are re-enumerated, so name the by-id
      # symlink instead; litra-autotoggle resolves it at startup (see the
      # patch on the package) and watches /dev for that node's events.
      facecam = "/dev/v4l/by-id/usb-Elgato_Elgato_Facecam_FW36L1A07812-video-index0";

      # Only the video device is pinned. With no device filter, every attached
      # Litra follows the camera (currently the Glow and the Beam LX front
      # light; add `back = true;` to also drive the Beam LX's backlight).
      configFile = (pkgs.formats.yaml { }).generate "litra-autotoggle.yml" {
        video_device = facecam;
        # Apps open and close the node a few times while starting a call, and
        # something on this box probes every /dev/video* node ~2x a second.
        # 1500ms is the upstream default and rides out both.
        delay = 1500;
      };

      # The watched node name is resolved once, at startup, so re-run the
      # daemon whenever the camera is (re)plugged and lands on a new index.
      facecamRules = pkgs.writeTextFile {
        name = "99-litra-autotoggle-facecam.rules";
        text = ''
          ACTION=="add", SUBSYSTEM=="video4linux", ATTR{index}=="0", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0078", RUN+="${pkgs.systemd}/bin/systemctl --no-block restart litra-autotoggle.service"
        '';
        destination = "/etc/udev/rules.d/99-litra-autotoggle-facecam.rules";
      };
    in
    {
      environment.systemPackages = [ pkgs.litra ];

      services.udev.packages = [
        # 99-litra.rules from upstream: GROUP="video" on the Litra hidraw
        # nodes, so both the CLI and the daemon work without root.
        pkgs.litra
        facecamRules
      ];

      systemd.services.litra-autotoggle = {
        description = "Turn the Litra lights on and off with the Elgato Facecam";
        documentation = [ "https://github.com/timrogers/litra-autotoggle" ];
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-udevd.service" ];

        serviceConfig = {
          Type = "simple";

          # The by-id symlink only exists once udev has processed the camera.
          # If it never turns up, start anyway — the udev rule above restarts
          # the unit when the camera does appear.
          ExecStartPre = pkgs.writeShellScript "wait-for-facecam" ''
            for _ in $(seq 30); do
              [ -e ${lib.escapeShellArg facecam} ] && exit 0
              sleep 1
            done
            echo "warning: ${facecam} never appeared" >&2
          '';
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
