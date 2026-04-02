{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchurl,
  electron_37,
  makeWrapper,
  python3,
  pkg-config,
  copyDesktopItems,
  makeDesktopItem,
}:
let
  # x-win v3.4.0 with KDE/wlroots Wayland support
  # The v2.x bundled with desktop-wakatime panics on non-GNOME compositors.
  # See: https://github.com/wakatime/desktop-wakatime/issues/104
  xwin-js = fetchurl {
    url = "https://registry.npmjs.org/@miniben90/x-win/-/x-win-3.4.0.tgz";
    hash = "sha256-14rx5FqkyzENah1SObR2GrHfzuaI/EagsBtrJJRWcck=";
  };
  xwin-native = fetchurl {
    url = "https://registry.npmjs.org/@miniben90/x-win-linux-x64-gnu/-/x-win-linux-x64-gnu-3.4.0.tgz";
    hash = "sha256-VS6MCtXTXj0lw+O00LRFyEp2/Pxzwf0uyCMOznT/eZ0=";
  };
in
buildNpmPackage rec {
  pname = "desktop-wakatime";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "wakatime";
    repo = "desktop-wakatime";
    tag = "v${version}";
    hash = "sha256-cXAy6cfBuGMWXN6d9ru34z6pXEhfJhX1R7CInzEXBqA=";
  };

  npmDepsHash = "sha256-Bny72Rm3KQOO3E2TWY5peEnFsdEqLrb+6LZXeJn3lU4=";

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
  # Adapt source for x-win v3 API change: subscribeActiveWindow callback
  # changed from (windowInfo) => void to (error, windowInfo) => void
  postPatch = ''
    substituteInPlace electron/watchers/watcher.ts \
      --replace-fail '(windowInfo: WindowInfo) => {' \
                     '(error: Error | null, windowInfo: WindowInfo | undefined) => {
        if (error || !windowInfo) return;'
  '';

  postConfigure = ''
    # Override the build script to skip electron-builder
    substituteInPlace package.json \
      --replace-fail '"build": "tsc && vite build && electron-builder"' \
                     '"build": "tsc && vite build"'

    # Replace x-win v2 with v3 for build (types + native binary)
    rm -rf node_modules/@miniben90/x-win
    rm -rf node_modules/@miniben90/x-win-linux-x64-gnu
    mkdir -p node_modules/@miniben90/x-win
    tar xzf ${xwin-js} --strip-components=1 -C node_modules/@miniben90/x-win
    mkdir -p node_modules/@miniben90/x-win-linux-x64-gnu
    tar xzf ${xwin-native} --strip-components=1 -C node_modules/@miniben90/x-win-linux-x64-gnu
  '';

  # vite-plugin-electron outputs to dist-electron/ (main + preload) and dist/ (renderer)
  postInstall = ''
    # Install the built app files
    mkdir -p $out/lib/desktop-wakatime
    cp -r dist-electron $out/lib/desktop-wakatime/
    cp -r dist $out/lib/desktop-wakatime/

    # Copy the renderer HTML entry points
    for f in monitored-apps.html settings.html; do
      [ -f "$f" ] && cp "$f" $out/lib/desktop-wakatime/
    done

    # Copy package.json (electron needs it to find the main entry)
    cp package.json $out/lib/desktop-wakatime/

    # Copy node_modules for native dependencies
    cp -r node_modules $out/lib/desktop-wakatime/

    # Replace x-win v2 with v3 in both node_modules locations
    # v2 panics on KDE/wlroots Wayland, v3 adds proper support
    # See: https://github.com/wakatime/desktop-wakatime/issues/104
    for nmdir in $out/lib/desktop-wakatime/node_modules $out/lib/node_modules/desktop-wakatime/node_modules; do
      rm -rf $nmdir/@miniben90/x-win
      rm -rf $nmdir/@miniben90/x-win-linux-x64-gnu
      mkdir -p $nmdir/@miniben90/x-win
      tar xzf ${xwin-js} --strip-components=1 -C $nmdir/@miniben90/x-win
      mkdir -p $nmdir/@miniben90/x-win-linux-x64-gnu
      tar xzf ${xwin-native} --strip-components=1 -C $nmdir/@miniben90/x-win-linux-x64-gnu
    done

    # Create the wrapper script
    makeWrapper ${electron_37}/bin/electron $out/bin/desktop-wakatime \
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
    homepage = "https://github.com/wakatime/desktop-wakatime";
    license = lib.licenses.bsd3;
    mainProgram = "desktop-wakatime";
    platforms = [ "x86_64-linux" ];
  };
}
