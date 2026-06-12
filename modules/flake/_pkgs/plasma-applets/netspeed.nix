{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  writeText,
}:
let
  # Plasma 6 removed the `org.kde.plasma.private.quicklaunch` QML import that
  # upstream's Launcher.qml used for its click-to-launch action. The import no
  # longer resolves, so plasmashell logs a fatal QML error and the launcher
  # Loader fails. Swap in a Qt.openUrlExternally launcher (routes through
  # xdg-open / kde-open), which still opens the configured .desktop entry on
  # Plasma 6 without depending on the removed private module.
  launcherQml = writeText "Launcher.qml" ''
    import QtQuick 2.5

    Item {
        function launch(url) {
            Qt.openUrlExternally(url)
        }
    }
  '';
in
stdenvNoCC.mkDerivation {
  pname = "plasma-applet-netspeed-widget";
  version = "3.1";

  src = fetchFromGitHub {
    owner = "dfaust";
    repo = "plasma-applet-netspeed-widget";
    rev = "v3.1";
    hash = "sha256-lP2wenbrghMwrRl13trTidZDz+PllyQXQT3n9n3hzrg=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -d "$out/share/plasma/plasmoids/org.kde.netspeedWidget"
    cp -r package/. "$out/share/plasma/plasmoids/org.kde.netspeedWidget/"
    # Plasma 6 launcher shim (drops the removed quicklaunch QML import)
    cp ${launcherQml} "$out/share/plasma/plasmoids/org.kde.netspeedWidget/contents/ui/Launcher.qml"
    runHook postInstall
  '';

  meta = {
    description = "KDE Plasma widget displaying current network bandwidth";
    homepage = "https://github.com/dfaust/plasma-applet-netspeed-widget";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
