{
  lib,
  pkgs,
  python3Packages,
  fetchFromGitHub,
  makeWrapper,
  wrapGAppsHook4,
  wtype,
  ydotool,
  gobject-introspection,
  gtk4,
  gtk4-layer-shell,
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
    wrapGAppsHook4
    gobject-introspection
  ];

  buildInputs = [
    gtk4
    gtk4-layer-shell
  ];

  dontBuild = true;

  # wrapGAppsHook4 would wrap the bin, but we need the GI_TYPELIB_PATH value
  # for the mic-osd subprocess too — extract it after wrapping
  dontWrapGApps = true;

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

    runHook postInstall
  '';

  preFixup = ''
    # Inject GI_TYPELIB_PATH and LD_PRELOAD into mic-osd daemon subprocess env
    # gappsWrapperArgs is populated by wrapGAppsHook4 with all transitive typelib paths
    local gi_path=""
    for arg in "''${gappsWrapperArgs[@]}"; do
      if [[ "$arg" == */girepository-1.0* ]]; then
        gi_path="$arg"
      fi
    done

    sed -i "s|env = os.environ.copy()|env = os.environ.copy(); env[\"GI_TYPELIB_PATH\"] = \"$gi_path\"; env[\"LD_PRELOAD\"] = \"${gtk4-layer-shell}/lib/libgtk4-layer-shell.so\"|" \
      $out/lib/hyprwhspr/mic_osd/runner.py

    # Now wrap the binary with everything
    wrapProgram $out/bin/hyprwhspr \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : ${
        lib.makeBinPath [
          wtype
          ydotool
          wl-clipboard
          pulseaudio
          pkgs.pipewire
        ]
      }
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
