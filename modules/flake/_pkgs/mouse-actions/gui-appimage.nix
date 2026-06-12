{
  lib,
  appimageTools,
  fetchurl,
}:
let
  pname = "mouse-actions-gui";
  version = "0.4.5";

  src = fetchurl {
    url = "https://github.com/jersou/mouse-actions/releases/download/v${version}/mouse-actions-gui_${version}_amd64.AppImage";
    hash = "sha256-v+aiphqFtrsMAElFgzi2hlQ/IwOKjZSwLrrQRX2TUl0=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # The AppImage already sets Exec=mouse-actions-gui in its bundled .desktop
  # file, which lines up with the wrapper's binary name; just copy it through
  # along with the hicolor icon theme so KDE/Plasma can find it.
  extraInstallCommands = ''
    install -Dm644 ${appimageContents}/usr/share/applications/mouse-actions-gui.desktop \
      $out/share/applications/mouse-actions-gui.desktop
    cp -r ${appimageContents}/usr/share/icons $out/share/icons
  '';

  meta = {
    description = "GUI for mouse-actions (AppImage, bundles webkit2gtk-4.0)";
    homepage = "https://github.com/jersou/mouse-actions";
    license = lib.licenses.mit;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
