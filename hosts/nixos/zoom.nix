{
  pkgs,
  lib,
  ...
}:
let
  # Native FHS Zoom package instead of Flatpak because the Flatpak sandbox
  # breaks Zoom's SQLCipher encrypted DB key derivation, causing login to be
  # lost on every launch.
  version = "6.7.5.6891";

  unpacked = pkgs.stdenv.mkDerivation {
    pname = "zoom";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://zoom.us/client/${version}/zoom_x86_64.pkg.tar.xz";
      hash = "sha256-Qy4o3vbgiAjKUGWMFi8rNqyDAohG7TgwX69jKVWTWeY=";
    };
    dontUnpack = true;
    dontPatchELF = true;
    installPhase = ''
      runHook preInstall
      mkdir $out
      tar -C $out -xf $src
      mv $out/usr/* $out/
      runHook postInstall
    '';
  };

  deps = pkgs: with pkgs; [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    coreutils
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    glib.dev
    kdePackages.kwallet
    gtk3
    libGL
    libGLU
    libdrm
    libgbm
    libkrb5
    libpulseaudio
    libsecret
    libxkbcommon
    nspr
    nss
    pango
    pciutils
    pipewire
    procps
    pulseaudio
    qt5.qt3d
    qt5.qtgamepad
    qt5.qtlottie
    qt5.qtmultimedia
    qt5.qtremoteobjects
    qt5.qtxmlpatterns
    stdenv.cc.cc
    udev
    util-linux
    wayland
    xdg-desktop-portal
    kdePackages.xdg-desktop-portal-kde
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
    xorg.libxshmfence
    xorg.xcbutilcursor
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    xorg.xcbutilwm
    zlib
  ];

  zoom = pkgs.buildFHSEnv {
    pname = "zoom";
    inherit version;
    targetPkgs = pkgs: (deps pkgs) ++ [ unpacked ];
    extraPreBwrapCmds = "unset QT_PLUGIN_PATH";
    extraBwrapArgs = [ "--ro-bind ${unpacked}/opt /opt" ];
    runScript = "/opt/zoom/ZoomLauncher";
    extraInstallCommands = ''
      cp -Rt $out/ ${unpacked}/share
      substituteInPlace \
          $out/share/applications/Zoom.desktop \
          --replace-fail Exec={/usr/bin/,}zoom
      ln -s $out/bin/{zoom,zoom-us}
    '';
    meta = {
      description = "zoom.us video conferencing application";
      homepage = "https://zoom.us/";
      license = lib.licenses.unfree;
      mainProgram = "zoom";
    };
  };
in
{
  home.packages = [ zoom ];
}
