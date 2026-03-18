# hosts/common/system/howdy.nix
# Howdy facial recognition with conditional gating
#
# Behavior:
#   - Boot/sleep/hibernate/lock → howdy disabled (password required)
#   - After successful login/sudo (PAM session open) → howdy enabled for 1 hour
#   - After successful auth (PAM account/session phase) → howdy enabled for 1 hour
#   - Manual or auto lock, or screen lock signal → howdy disabled immediately
#
# Note: howdy is only in nixpkgs-unstable, so we use pkgs.unstable.howdy.
# The upstream NixOS module (services.howdy) is not available in 25.11,
# so we configure PAM and the config file manually.
{
  config,
  pkgs,
  lib,
  username,
  ...
}:
let
  howdy = pkgs.unstable.howdy;
  pam = config.security.pam.package;

  # Udev rules: stable symlinks for both cameras on the Lenovo Performance Camera.
  # The device exposes two USB interfaces: 00 = color (RGB), 02 = IR.
  # Both have index==0 and the same vendor/product, so bInterfaceNumber is required
  # to tell them apart (without it, both match and /dev/howdy-camera is ambiguous).
  # Howdy uses the IR camera (/dev/howdy-camera-ir) for lighting-invariant recognition.
  howdy-camera-rules = pkgs.writeTextFile {
    name = "99-howdy-camera.rules";
    text = ''
      SUBSYSTEM=="video4linux", ATTR{index}=="0", ATTRS{idVendor}=="17ef", ATTRS{idProduct}=="4839", ENV{ID_USB_INTERFACE_NUM}=="00", SYMLINK+="howdy-camera", TAG+="uaccess"
      SUBSYSTEM=="video4linux", ATTR{index}=="0", ATTRS{idVendor}=="17ef", ATTRS{idProduct}=="4839", ENV{ID_USB_INTERFACE_NUM}=="02", SYMLINK+="howdy-camera-ir", TAG+="uaccess"
    '';
    destination = "/etc/udev/rules.d/99-howdy-camera.rules";
  };

  howdy-gate-check = pkgs.writeShellScript "howdy-gate-check" ''
    if [ -f /run/howdy/enabled ]; then
      exit 0
    fi
    exit 1
  '';

  howdy-gate-enable = pkgs.writeShellScript "howdy-gate-enable" ''
    touch /run/howdy/enabled
    systemctl restart howdy-gate-timeout.timer 2>/dev/null || true
  '';

  howdy-gate-disable = pkgs.writeShellScript "howdy-gate-disable" ''
    rm -f /run/howdy/enabled
    systemctl stop howdy-gate-timeout.timer 2>/dev/null || true
  '';

  howdy-lock-monitor = pkgs.writeShellScript "howdy-lock-monitor" ''
    ${pkgs.dbus}/bin/dbus-monitor --session "interface='org.freedesktop.ScreenSaver',member='ActiveChanged'" |
      while read -r line; do
        if echo "$line" | ${lib.getExe pkgs.gnugrep} -q "boolean true"; then
          ${howdy-gate-disable}
        fi
      done
  '';

  # Generate howdy config.ini
  howdyConfig = pkgs.writeText "howdy-config.ini" ''
    [core]
    detection_notice = true
    no_confirmation = true
    abort_if_ssh = true
    abort_if_lid_closed = true

    [video]
    certainty = 3.5
    timeout = 4
    device_path = /dev/howdy-camera-ir
    recording_plugin = v4l2

    [snapshots]
    save_failed = false
    save_successful = false

    [rubberstamps]
    enabled = false

    [debug]
    end_report = false
  '';

  # PAM services that should have howdy gating
  gatedServices = [
    "login"
    "sddm"
    "kde"
    "sudo"
    "polkit-1"
  ];

  mkGatedService = name: {
    inherit name;
    value = {
      rules.auth = {
        # Gate: check if howdy is currently enabled. If not, skip the next rule (howdy).
        # [success=ok default=1] means: if gate passes → continue (try howdy);
        # if gate fails → skip 1 rule (skip howdy, fall through to password)
        howdy-gate = {
          order = config.security.pam.services.${name}.rules.auth.unix.order - 30;
          control = "[success=ok default=1]";
          modulePath = "${pam}/lib/security/pam_exec.so";
          args = [
            "quiet"
            "${howdy-gate-check}"
          ];
        };
        # Howdy face auth (sufficient = if face matches, auth succeeds)
        howdy = {
          order = config.security.pam.services.${name}.rules.auth.unix.order - 20;
          control = "sufficient";
          modulePath = "${howdy}/lib/security/pam_howdy.so";
        };
        # pam_unix left as default "sufficient" - stack terminates here on password success
      };
      # Account phase: enable howdy after successful auth.
      # GUI auth agents (polkit) call pam_acct_mgmt() but not pam_open_session(),
      # so the session phase alone misses GUI password prompts.
      rules.account = {
        howdy-gate-enable = {
          order = 1000;
          control = "optional";
          modulePath = "${pam}/lib/security/pam_exec.so";
          args = [
            "quiet"
            "${howdy-gate-enable}"
          ];
        };
      };
      # Session phase: also enable here for services that open full sessions
      # (login, sudo) as a belt-and-suspenders approach.
      # Lock screen unlock is handled by howdy-lock-monitor watching ActiveChanged=false.
      rules.session = {
        howdy-gate-enable = {
          order = 1000;
          control = "optional";
          modulePath = "${pam}/lib/security/pam_exec.so";
          args = [
            "quiet"
            "${howdy-gate-enable}"
          ];
        };
      };
    };
  };
in
{
  # Install howdy and its config
  environment.systemPackages = [ howdy ];

  # Persistent camera symlink
  services.udev.packages = [ howdy-camera-rules ];

  # Create /run/howdy with open write permissions so pam_exec scripts
  # (which run as the authenticating user) can create/remove the gate flag
  systemd.tmpfiles.rules = [
    "d /run/howdy 0777 root root -"
  ];

  # Allow managing howdy-gate systemd units without polkit auth popup
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          (action.lookup("unit") == "howdy-gate-timeout.timer" ||
           action.lookup("unit") == "howdy-gate-timeout-disable.service")) {
        return polkit.Result.YES;
      }
    });
  '';

  # polkit-127 runs polkit-agent-helper in a sandboxed unit that blocks camera access.
  # https://github.com/NixOS/nixpkgs/issues/483867
  systemd.services."polkit-agent-helper@".serviceConfig = {
    DeviceAllow = "char-video4linux rw";
    PrivateDevices = "no";
  };

  environment.etc."howdy/config.ini" = {
    source = howdyConfig;
  };

  # PAM gating
  security.pam.services = builtins.listToAttrs (map mkGatedService gatedServices);

  # Systemd services for state management
  systemd.services = {
    howdy-gate-boot-disable = {
      description = "Disable howdy face auth on boot";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${howdy-gate-disable}";
        RemainAfterExit = true;
      };
    };

    howdy-gate-sleep-disable = {
      description = "Disable howdy face auth on sleep/hibernate";
      wantedBy = [
        "sleep.target"
        "hibernate.target"
        "hybrid-sleep.target"
      ];
      before = [
        "sleep.target"
        "hibernate.target"
        "hybrid-sleep.target"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${howdy-gate-disable}";
      };
    };

    howdy-lock-monitor = {
      description = "Monitor screen lock to disable howdy";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${howdy-lock-monitor}";
        Restart = "on-failure";
        RestartSec = 5;
        User = username;
      };
    };

    howdy-gate-timeout-disable = {
      description = "Disable howdy after 1hr timeout";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${howdy-gate-disable}";
      };
    };
  };

  systemd.timers.howdy-gate-timeout = {
    description = "1hr timeout to disable howdy face auth";
    timerConfig = {
      OnActiveSec = "1h";
      AccuracySec = "1min";
      Unit = "howdy-gate-timeout-disable.service";
    };
  };
}
