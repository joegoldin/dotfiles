# modules/system/_sys/howdy.nix
# Howdy facial recognition - only for unlocked-session auth (sudo, polkit)
#
# Behavior:
#   - sudo / polkit prompts → howdy face auth attempted, falls back to password
#   - Lock screen / SDDM login / console login → password only (howdy not in PAM stack)
#
# Implementation: NixOS 26.05 ships a built-in `services.howdy` module that
# also wires up PAM. We enable it for the package + config.ini, but disable
# the system-wide PAM default and opt in per-service so only sudo + polkit-1
# get howdy. Howdy itself is only in nixpkgs-unstable, hence pkgs.unstable.
{ ... }:
{
  den.aspects.howdy.nixos =
    {
      pkgs,
      ...
    }:
    let
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
    in
    {
      services.howdy = {
        enable = true;
        package = pkgs.unstable.howdy;
        control = "sufficient";
        settings = {
          core = {
            detection_notice = true;
            no_confirmation = true;
            abort_if_ssh = true;
            abort_if_lid_closed = true;
          };
          video = {
            certainty = 3.5;
            timeout = 4;
            device_path = "/dev/howdy-camera-ir";
            recording_plugin = "v4l2";
          };
          snapshots = {
            save_failed = false;
            save_successful = false;
          };
          rubberstamps.enabled = false;
          debug.end_report = false;
        };
      };

      # Persistent camera symlinks
      services.udev.packages = [ howdy-camera-rules ];

      # polkit-127 runs polkit-agent-helper in a sandboxed unit that blocks camera access.
      # https://github.com/NixOS/nixpkgs/issues/483867
      systemd.services."polkit-agent-helper@".serviceConfig = {
        DeviceAllow = "char-video4linux rw";
        PrivateDevices = "no";
      };

      # Don't put howdy into every PAM stack by default; opt in per-service below.
      security.pam.howdy.enable = false;
      security.pam.services.sudo.howdy.enable = true;
      security.pam.services."polkit-1".howdy.enable = true;
    };
}
