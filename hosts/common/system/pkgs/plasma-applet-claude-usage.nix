{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "plasma-applet-claude-usage";
  version = "1.3.6-unstable-2026-04-01";

  src = fetchFromGitHub {
    owner = "izll";
    repo = "plasma-claude-usage";
    rev = "eca1b9a7c521d8a3e45f1aa2f4f825d572dc611e";
    hash = "sha256-53Lkog5q/xJWxMebAtndB/6/9k9rUQ5lzK8VCe4Vlhc=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -d "$out/share/plasma/plasmoids/org.kde.plasma.claudeusage"
    cp -r contents metadata.json "$out/share/plasma/plasmoids/org.kde.plasma.claudeusage/"
    runHook postInstall
  '';

  meta = {
    description = "KDE Plasma widget showing Claude Code session and weekly usage";
    homepage = "https://github.com/izll/plasma-claude-usage";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
