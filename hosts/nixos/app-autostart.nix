{
  pkgs,
  ...
}:
let
  streamcontroller-wrapped = pkgs.unstable.streamcontroller.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/streamcontroller \
        --set GSK_RENDERER ngl
    '';
  });

  startupScript = pkgs.writeShellScript "audio-app-autostart" ''
    export PATH="${pkgs.pipewire}/bin:${pkgs.pulseaudio}/bin:$PATH"

    echo "Waiting for PulseAudio to be ready..."
    for i in $(seq 1 30); do
      if ${pkgs.pulseaudio}/bin/pactl info &>/dev/null; then
        echo "PulseAudio ready after $i attempts"
        break
      fi
      sleep 1
    done

    wait_and_close() {
      local app_name="$1"
      local search_term="$2"
      local timeout=30
      local elapsed=0

      echo "Starting $app_name..."
      "$app_name" &

      echo "Waiting for $app_name window..."
      while [ "$elapsed" -lt "$timeout" ]; do
        wid=$(${pkgs.kdotool}/bin/kdotool search --name "$search_term" 2>/dev/null | head -1) || true
        if [ -n "$wid" ]; then
          echo "Found $app_name window ($wid), closing..."
          sleep 1
          ${pkgs.kdotool}/bin/kdotool windowclose "$wid" 2>/dev/null || true
          return 0
        fi
        sleep 0.5
        elapsed=$((elapsed + 1))
      done

      echo "Timed out waiting for $app_name window"
      return 0
    }

    wait_and_close "${pkgs.unstable.pulsemeeter}/bin/pulsemeeter" "PulseMeeter"

    sleep 1

    ${streamcontroller-wrapped}/bin/streamcontroller -b &
    echo "Started StreamController in background mode"
  '';
in
{
  systemd.user.services."audio-app-autostart" = {
    description = "Start PulseMeeter and StreamController after login";
    wantedBy = [ "graphical-session.target" ];
    requires = [ "pipewire-pulse.service" ];
    after = [
      "graphical-session.target"
      "pipewire.service"
      "pipewire-pulse.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = startupScript;
      RemainAfterExit = true;
    };
  };

  systemd.user.services."1password-autostart" = {
    description = "Start 1Password after login";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
      RemainAfterExit = true;
    };
  };
}
