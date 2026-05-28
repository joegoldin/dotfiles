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

  # Install the bundled .desktop entry + icon. Tauri's AppImage points Exec
  # at the AppRun inside the squashfs, so rewrite it to the wrapped binary.
  extraInstallCommands = ''
    install -Dm644 ${appimageContents}/mouse-actions-gui.desktop \
      $out/share/applications/mouse-actions-gui.desktop
    substituteInPlace $out/share/applications/mouse-actions-gui.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}'
    cp -r ${appimageContents}/usr/share/icons $out/share/icons || true
  '';

  meta = {
    description = "GUI for mouse-actions (AppImage, bundles webkit2gtk-4.0)";
    homepage = "https://github.com/jersou/mouse-actions";
    license = lib.licenses.mit;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
