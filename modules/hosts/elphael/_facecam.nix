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

  # Emits an "on" line when the camera starts streaming and an "off" line when
  # it stops. Device opens are useless as a signal here: Zoom probes every
  # /dev/video* node twice a second while idle and sometimes holds ours open
  # without capturing, so the only honest signal is USB traffic — the device's
  # urbnum counter climbs ~1000/s while frames flow and, measured against live
  # probing, not at all otherwise. One hot second turns on; three quiet ones
  # turn off, riding out mid-call renegotiation.
  watchStreaming = pkgs.writeShellApplication {
    name = "facecam-watch-streaming";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      dev=$(readlink -f ${lib.escapeShellArg path} 2> /dev/null || true)
      if [ -z "$dev" ] || [ ! -e "$dev" ]; then
        # Idle rather than exit, so restart-happy consumers do not churn;
        # udev restarts the consuming unit when the camera turns up.
        echo "${path} is absent; nothing to watch" >&2
        exec sleep infinity
      fi

      # /sys/class/video4linux/videoN/device is the USB interface; its parent
      # is the device, which carries the urbnum counter.
      urbnum=$(dirname "$(readlink -f "/sys/class/video4linux/$(basename "$dev")/device")")/urbnum
      echo "watching $urbnum for $dev" >&2

      state=off
      quiet=0
      prev=$(cat "$urbnum")
      # cat failing means the camera was unplugged: fall out through the exit
      # below and let udev start us again on plug.
      while sleep 1 && cur=$(cat "$urbnum" 2> /dev/null); do
        delta=$((cur - prev))
        prev=$cur
        if [ "$delta" -ge 100 ]; then
          quiet=0
          if [ "$state" = off ]; then
            state=on
            echo on
          fi
        elif [ "$state" = on ]; then
          quiet=$((quiet + 1))
          if [ "$quiet" -ge 3 ]; then
            state=off
            echo off
          fi
        fi
      done

      # Leave consumers in the "camera off" state rather than frozen mid-call.
      if [ "$state" = on ]; then
        echo off
      fi
      echo "$dev disappeared; exiting" >&2
    '';
  };

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
