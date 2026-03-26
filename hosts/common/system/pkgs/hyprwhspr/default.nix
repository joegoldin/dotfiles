{
  lib,
  pkgs,
  python3Packages,
  fetchFromGitHub,
  makeWrapper,
  wtype,
  ydotool,
  gobject-introspection,
  gtk4,
  gtk4-layer-shell,
  glib,
  wl-clipboard,
  pulseaudio,
}:
let
  pywhispercpp = pkgs.callPackage ./pywhispercpp.nix { };
  python = python3Packages.python.withPackages (
    ps: with ps; [
      sounddevice
      numpy
      scipy
      evdev
      pyperclip
      requests
      websocket-client
      psutil
      pyudev
      pulsectl
      dbus-python
      pygobject3
      rich
      elevenlabs
      pywhispercpp
    ]
  );
in
python3Packages.buildPythonApplication rec {
  pname = "hyprwhspr";
  version = "1.24.0";

  src = fetchFromGitHub {
    owner = "goodroot";
    repo = "hyprwhspr";
    tag = "v${version}";
    hash = "sha256-WNvAVuSU/DXWJp2NZjfKlFczwHd6YRTg9s3NiOY+NGU=";
  };

  format = "other";

  nativeBuildInputs = [
    makeWrapper
    gobject-introspection
  ];

  dontBuild = true;

  postPatch = ''
    substituteInPlace lib/mic_osd/runner.py \
      --replace-fail "/usr/bin/python3" "${python}/bin/python3"
  '';

  installPhase = ''
    runHook preInstall

    # Install library files
    mkdir -p $out/lib/hyprwhspr
    cp -r lib/* $out/lib/hyprwhspr/

    # Install assets and config under HYPRWHSPR_ROOT (code expects share/assets/)
    cp -r share $out/share
    cp -r config $out/config

    # Create launcher that bypasses upstream bash script (uses #!/bin/bash)
    mkdir -p $out/bin
    cat > $out/bin/hyprwhspr <<WRAPPER
    #!${python}/bin/python3
    import sys, os
    os.environ["HYPRWHSPR_ROOT"] = "${placeholder "out"}"
    lib_dir = os.path.join("${placeholder "out"}", "lib", "hyprwhspr")
    sys.path.insert(0, lib_dir)

    # Route subcommands to CLI, everything else to main
    cli_commands = {"setup", "install", "config", "waybar", "systemd", "status",
                    "model", "validate", "uninstall", "backend", "state",
                    "mic-osd", "keyboard", "record", "test", "help"}
    if len(sys.argv) > 1 and sys.argv[1] in cli_commands:
        from cli import main
        main()
    elif "--help" in sys.argv or "-h" in sys.argv:
        from cli import main
        sys.argv = [sys.argv[0], "--help"]
        main()
    else:
        from main import main
        main()
    WRAPPER
    chmod +x $out/bin/hyprwhspr

    wrapProgram $out/bin/hyprwhspr \
      --prefix PATH : ${
        lib.makeBinPath [
          wtype
          ydotool
          wl-clipboard
          pulseaudio
        ]
      } \
      --prefix GI_TYPELIB_PATH : "${gtk4}/lib/girepository-1.0:${glib}/lib/girepository-1.0:${gtk4-layer-shell}/lib/girepository-1.0"

    runHook postInstall
  '';

  meta = {
    description = "System-wide speech-to-text for Hyprland/Wayland";
    homepage = "https://github.com/goodroot/hyprwhspr";
    license = lib.licenses.mit;
    mainProgram = "hyprwhspr";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
