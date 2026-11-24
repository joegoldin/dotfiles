{
  fetchurl,
  lib,
  panelTool,
  stdenvNoCC,
  systemdRun,
}:
stdenvNoCC.mkDerivation {
  pname = "plasma-applet-owly-share";
  version = "0.2";

  src = fetchurl {
    url = "https://codefloe.com/ruka/owly-share/archive/8a1e6e6e800284b6bf3fe57ba1201de6d38650aa.tar.gz";
    hash = "sha256-OMFOH7hV7A8VH6GOlQUouR1B37oEqxXUMICnTE0EQYs=";
  };

  patches = [ ./panel.patch ];
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    widget="$out/share/plasma/plasmoids/red.ruka.owlyshare"
    mkdir -p "$widget"
    cp -r plasmoid/red.ruka.owlyshare/. "$widget/"
    substituteInPlace "$widget/contents/ui/main.qml" \
      --replace-fail '@panelTool@' '${panelTool}' \
      --replace-fail '@systemdRun@' '${systemdRun}'
    runHook postInstall
  '';

  meta = {
    description = "Owly Share's Plasma applet with a per-user receiver";
    homepage = "https://codefloe.com/ruka/owly-share";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
