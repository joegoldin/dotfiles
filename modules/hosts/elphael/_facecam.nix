# The Elgato Facecam's capture node, shared by the units that follow the
# camera: ./litra.nix and ./led-signs.nix.
{ lib, pkgs }:
rec {
  # /dev/videoN is handed out in probe order and moves when USB devices are
  # re-enumerated, so name the by-id symlink and resolve it at runtime.
  path = "/dev/v4l/by-id/usb-Elgato_Elgato_Facecam_FW36L1A07812-video-index0";

  # udev creates the by-id symlink only once it has processed the camera.
  waitForDevice = pkgs.writeShellScript "wait-for-facecam" ''
    for _ in $(seq 30); do
      [ -e ${lib.escapeShellArg path} ] && exit 0
      sleep 1
    done
    echo "warning: ${path} never appeared" >&2
  '';

  # Consumers resolve the node name once, at startup, so they need restarting
  # when the camera is replugged and lands on a new index.
  restartOnReplug =
    unit:
    pkgs.writeTextFile {
      name = "99-facecam-restart-${unit}.rules";
      text = ''
        ACTION=="add", SUBSYSTEM=="video4linux", ATTR{index}=="0", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0078", RUN+="${pkgs.systemd}/bin/systemctl --no-block restart ${unit}"
      '';
      destination = "/etc/udev/rules.d/99-facecam-restart-${unit}.rules";
    };
}
