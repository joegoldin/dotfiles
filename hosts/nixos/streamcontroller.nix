{ pkgs }:
let
  package = (pkgs.unstable.streamcontroller.override { isKde = true; }).overrideAttrs (old: {
    version = "1.5.0-unstable-2025-03-03";
    src = pkgs.fetchFromGitHub {
      owner = "joegoldin";
      repo = "StreamController";
      rev = "2381ccee631be5dc49bc63e471c6e37d4448ed2d";
      hash = "sha256-igMFQNs/4CKOlDmwWkOP+XYXRldVAh7x0ubKh20RDPQ=";
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
