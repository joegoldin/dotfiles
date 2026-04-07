{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  electron_38,
  makeWrapper,
  python3,
  pkg-config,
  copyDesktopItems,
  makeDesktopItem,
}:
buildNpmPackage {
  pname = "desktop-wakatime";
  version = "3.0.0-kde";

  src = fetchFromGitHub {
    owner = "joegoldin";
    repo = "desktop-wakatime";
    rev = "06c7d0e";
    hash = "sha256-K2EdzT/6/Y3dARksK55iM7mYk0AUXp+sywJQ7hTVCqM=";
  };

  npmDepsHash = "sha256-Kjt3Tu2Ez8kJ5HkonCd36ZpGEzXNGSWIPATf21qIpSs=";

  nativeBuildInputs = [
    makeWrapper
    python3
    pkg-config
    copyDesktopItems
  ];

  makeCacheWritable = true;

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  };

  # Run tsc && vite build, but skip electron-builder
  npmBuildScript = "build";

  postConfigure = ''
    # Override the build script to skip electron-builder
    substituteInPlace package.json \
      --replace-fail '"build": "tsc && vite build && electron-builder"' \
                     '"build": "tsc && vite build"'
  '';

  # vite-plugin-electron outputs to dist-electron/ (main + preload) and dist/ (renderer)
  postInstall = ''
    # Install the built app files
    mkdir -p $out/lib/desktop-wakatime
    cp -r dist-electron $out/lib/desktop-wakatime/
    cp -r dist $out/lib/desktop-wakatime/

    # Copy public/ for tray icons (VITE_PUBLIC points here when not packaged)
    cp -r public $out/lib/desktop-wakatime/

    # Copy the renderer HTML entry points
    for f in monitored-apps.html settings.html; do
      [ -f "$f" ] && cp "$f" $out/lib/desktop-wakatime/
    done

    # Copy package.json (electron needs it to find the main entry)
    cp package.json $out/lib/desktop-wakatime/

    # Copy node_modules for native dependencies
    cp -r node_modules $out/lib/desktop-wakatime/

    # Create the wrapper script
    makeWrapper ${electron_38}/bin/electron $out/bin/desktop-wakatime \
      --add-flags $out/lib/desktop-wakatime/dist-electron/main.js

    # Install icon
    install -Dm644 build/icon.png \
      $out/share/icons/hicolor/512x512/apps/desktop-wakatime.png \
      2>/dev/null || true
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "desktop-wakatime";
      exec = "desktop-wakatime %U";
      icon = "desktop-wakatime";
      desktopName = "WakaTime";
      comment = "System tray app for automatic time tracking across desktop applications";
      categories = [
        "Utility"
        "Development"
      ];
      mimeTypes = [ "x-scheme-handler/wakatime" ];
    })
  ];

  meta = {
    description = "System tray app for automatic time tracking across desktop applications";
    homepage = "https://github.com/joegoldin/desktop-wakatime";
    license = lib.licenses.bsd3;
    mainProgram = "desktop-wakatime";
    platforms = [ "x86_64-linux" ];
  };
}
