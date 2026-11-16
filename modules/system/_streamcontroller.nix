{ pkgs }:
let
  package = (pkgs.unstable.streamcontroller.override { isKde = true; }).overrideAttrs (old: {
    version = "1.5.0-beta.15-unstable-2026-11-16";
    src = pkgs.fetchFromGitHub {
      owner = "joegoldin";
      repo = "StreamController";
      # Fork main includes StreamDock support, event-driven KWin tracking and
      # main-thread generative ComboRow repopulation (GTK4 startup crash fix).
      rev = "14a93b8a3ff394a5f70176de762d52594d80aab4";
      hash = "sha256-L3n/xstKovxjGOkiTFBGdrSgXLbMu15mkcjQynWCdZU=";
    };
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    # The upstream nixpkgs derivation builds the Python env from a fixed list,
    # so hidapi (added to requirements.txt by PR #2) is missing and the MiraBox
    # StreamDock backend silently disables itself ("is 'hidapi' installed?").
    # Add it so `import hid` resolves and StreamDock devices are detected.
    # Same for dasbus: beta.15 added src/api.py (D-Bus API), imported
    # unconditionally at startup, so the app crashes at launch without it.
    buildInputs =
      (old.buildInputs or [ ])
      ++ (with pkgs.unstable.python3Packages; [
        hidapi
        dasbus
      ]);
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
