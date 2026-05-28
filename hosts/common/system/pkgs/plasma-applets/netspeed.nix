{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
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
    runHook postInstall
  '';

  meta = {
    description = "KDE Plasma widget displaying current network bandwidth";
    homepage = "https://github.com/dfaust/plasma-applet-netspeed-widget";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
