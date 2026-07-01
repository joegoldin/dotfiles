{ pkgs }:
let
  package = (pkgs.unstable.streamcontroller.override { isKde = true; }).overrideAttrs (old: {
    version = "1.5.0-beta.14-unstable-2026-07-01";
    src = pkgs.fetchFromGitHub {
      owner = "joegoldin";
      repo = "StreamController";
      # PR #1 (MiraBox StreamDock device support) rebased onto main, so it also
      # carries the watcher-thread teardown fix (stops the runaway kdotool/KWin
      # script storm that wedged plasmashell's D-Bus) and the ComboRow GTK
      # main-thread fix from main. See joegoldin/StreamController#1.
      rev = "9a4c388b4eca1b5b820ae2cb316602dc7183f768";
      hash = "sha256-VFxirAlEyaZyN95E0ktCH8DztW6hoNumrA3sLEBw12Q=";
    };
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    # The upstream nixpkgs derivation builds the Python env from a fixed list,
    # so hidapi (added to requirements.txt by PR #1) is missing and the MiraBox
    # StreamDock backend silently disables itself ("is 'hidapi' installed?").
    # Add it so `import hid` resolves and StreamDock devices are detected.
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.unstable.python3Packages.hidapi ];
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
