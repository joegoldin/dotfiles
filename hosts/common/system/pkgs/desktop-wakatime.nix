{
  lib,
  appimageTools,
  fetchurl,
}:
let
  pname = "desktop-wakatime";
  version = "3.0.0";

  src = fetchurl {
    url = "https://github.com/wakatime/desktop-wakatime/releases/download/v${version}/wakatime-linux-x86_64.AppImage";
    hash = "sha256-8JdSzqJOqZngesjho8mkF88YL8YsRgHanrdnceZOZms=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm644 ${appimageContents}/desktop-wakatime.desktop $out/share/applications/desktop-wakatime.desktop
    substituteInPlace $out/share/applications/desktop-wakatime.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=desktop-wakatime'
    cp -r ${appimageContents}/usr/share/icons $out/share/icons
  '';

  meta = {
    description = "System tray app for automatic time tracking across desktop applications";
    homepage = "https://github.com/wakatime/desktop-wakatime";
    license = lib.licenses.bsd3;
    mainProgram = "desktop-wakatime";
    platforms = [ "x86_64-linux" ];
  };
}
