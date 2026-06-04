{ pkgs }:
let
  package = (pkgs.unstable.streamcontroller.override { isKde = true; }).overrideAttrs (old: {
    version = "1.5.0-beta.14-unstable-2026-06-04";
    src = pkgs.fetchFromGitHub {
      owner = "joegoldin";
      repo = "StreamController";
      rev = "40af8f66ff0caaf42adb79434626a95811ce40b7";
      hash = "sha256-olXNfkCU8sPTmOcxBeN6Qwf6fpOIJbW2VeXLeoCInEc=";
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
