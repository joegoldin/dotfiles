{ pkgs }:
let
  package = (pkgs.unstable.streamcontroller.override { isKde = true; }).overrideAttrs (old: {
    version = "1.5.0-beta.15-unstable-2026-07-10";
    src = pkgs.fetchFromGitHub {
      owner = "joegoldin";
      repo = "StreamController";
      # PR #1 (MiraBox StreamDock device support), rebased onto fork main =
      # upstream beta.15 + the fork's GTK-threading/watcher stability fixes.
      # Carries the N3 sleep/lock recovery: USB reset + official MOD handshake
      # clears the firmware's "host gone" latch (frozen display after suspend
      # or lock; writes ACKed but ignored). See joegoldin/StreamController#1.
      rev = "c14ead9e32444988460fa119e9cef7b800e9d2b4";
      hash = "sha256-GgI1cowszEr+n9lvlgYGBfYWWbhONGjo5hzCbNwXXTA=";
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
