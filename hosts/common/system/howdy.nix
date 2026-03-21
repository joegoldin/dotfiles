# hosts/common/system/howdy.nix
# Howdy facial recognition - only for unlocked-session auth (sudo, polkit)
#
# Behavior:
#   - sudo / polkit prompts → howdy face auth attempted, falls back to password
#   - Lock screen / SDDM login / console login → password only (howdy not in PAM stack)
#
# Note: howdy is only in nixpkgs-unstable, so we use pkgs.unstable.howdy.
{
  config,
  pkgs,
  ...
}:
let
  howdy = pkgs.unstable.howdy;

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

  # Only services that run while the machine is already unlocked
  howdyServices = [
    "sudo"
    "polkit-1"
  ];

  mkHowdyService = name: {
    inherit name;
    value = {
      rules.auth = {
        howdy = {
          order = config.security.pam.services.${name}.rules.auth.unix.order - 20;
          control = "sufficient";
          modulePath = "${howdy}/lib/security/pam_howdy.so";
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

  # polkit-127 runs polkit-agent-helper in a sandboxed unit that blocks camera access.
  # https://github.com/NixOS/nixpkgs/issues/483867
  systemd.services."polkit-agent-helper@".serviceConfig = {
    DeviceAllow = "char-video4linux rw";
    PrivateDevices = "no";
  };

  environment.etc."howdy/config.ini" = {
    source = howdyConfig;
  };

  # PAM: add howdy only to unlocked-session services
  security.pam.services = builtins.listToAttrs (map mkHowdyService howdyServices);
}
