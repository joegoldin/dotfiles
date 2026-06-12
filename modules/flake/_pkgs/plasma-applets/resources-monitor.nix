{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "plasma-applet-resources-monitor";
  version = "3.2.1";

  src = fetchFromGitHub {
    owner = "orblazer";
    repo = "plasma-applet-resources-monitor";
    rev = "v3.2.1";
    hash = "sha256-uP1TjH7vFIB9DO9SJXOLsQGQ7CRjGNuPY8c4vszIHmk=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -d "$out/share/plasma/plasmoids/org.kde.plasma.resources-monitor"
    cp -r package/. "$out/share/plasma/plasmoids/org.kde.plasma.resources-monitor/"
    # Drop the translation sources; the .po files are only useful when compiled
    # to .mo via msgfmt, and shipping them here would just inflate the closure.
    rm -rf "$out/share/plasma/plasmoids/org.kde.plasma.resources-monitor/translate"
    runHook postInstall
  '';

  meta = {
    description = "KDE Plasma widget monitoring CPU, memory, network, GPU and disk I/O";
    homepage = "https://github.com/orblazer/plasma-applet-resources-monitor";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
