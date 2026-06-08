{ pkgs }:
let
  package = (pkgs.unstable.streamcontroller.override { isKde = true; }).overrideAttrs (old: {
    version = "1.5.0-beta.14-unstable-2026-06-08";
    src = pkgs.fetchFromGitHub {
      owner = "joegoldin";
      repo = "StreamController";
      # Includes the watcher-thread teardown fix (8f04298): stops the runaway
      # kdotool/KWin-script storm that flooded the session bus and was the most
      # likely trigger for plasmashell's D-Bus connection wedging on app launch.
      rev = "8f04298a2ce0a1950aa3fdc5deee0ce6195ccdb8";
      hash = "sha256-ZWXVGXFOT4OgZvfdRZvxu8pncJBjU1lUB7lP0/uMpHM=";
    };
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/streamcontroller \
        --set GSK_RENDERER ngl
    '';
  });

  startupScript = pkgs.writeShellScript "streamcontroller-autostart" ''
    if ${pkgs.procps}/bin/pgrep -x StreamController >/dev/null 2>&1; then
      echo "StreamController is already running, skipping."
      exit 0
    fi

    echo "Waiting for PulseMeeter service to complete..."
    for i in $(seq 1 60); do
      if ${pkgs.systemd}/bin/systemctl --user is-active audio-app-autostart.service &>/dev/null; then
        echo "PulseMeeter service ready"
        break
      fi
      sleep 1
    done
    echo "Starting StreamController..."
    exec ${package}/bin/streamcontroller -b
  '';

  autostartDesktopEntry = ''
    [Desktop Entry]
    Type=Application
    Name=StreamController
    Exec=${startupScript}
  '';
in
{
  inherit package autostartDesktopEntry;
}
