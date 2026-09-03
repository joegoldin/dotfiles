# Packages unique to elphael; shared linux-workstation packages live in
# modules/home/_hm/packages/linux-workstation.nix, cross-platform tools in
# modules/home/_hm/packages/{default,workstation}.nix.
{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) unstable;
  goModule = import ../../../home/_go.nix { inherit pkgs lib; };
  appImagePackages = import ../../../home/_appimages.nix { inherit pkgs; };

  # UnityShaderCompiler links against libtinfo.so.6. nixpkgs ships that name as
  # a symlink to libncursesw.so.6.6, whose SONAME is libncursesw.so.6, so the
  # FHS env's ldconfig indexes it under that name and the libtinfo.so.6 lookup
  # misses -- the compiler dies in the loader and Unity aborts waiting for its
  # IPC connection (error 0x80000008). Ship a copy with a matching SONAME.
  libtinfo-compat = pkgs.runCommand "libtinfo-compat" { nativeBuildInputs = [ pkgs.patchelf ]; } ''
    mkdir -p $out/lib
    cp ${pkgs.ncurses}/lib/libncursesw.so.6 $out/lib/libtinfo.so.6
    chmod +w $out/lib/libtinfo.so.6
    patchelf --set-soname libtinfo.so.6 $out/lib/libtinfo.so.6
  '';

  packageGroups = with pkgs; {
    cli = [
      goModule.packages.claude-squad
      blip-caption
      bubblewrap
      gcc15
      glibc
      unstable.jdk25_headless
      libgcc
      reptyr
      rocmPackages.rocm-smi
    ];

    gui = [
      affinity-v3
      unstable.audacity
      cameractrls-gtk3
      claude-desktop-fhs
      unstable.darktable
      # unstable.davinci-resolve
      unstable.discord
      # Autodesk Fusion. The wine prefix and Fusion itself are built by nix
      # (inputs.fusion-360-flake) and ship in the closure, so this is installed
      # by `just switch` rather than on first launch.
      fusion360
      # hyprwhspr
      unstable.jellyfin-desktop
      unstable.kdePackages.kdenlive
      unstable.kicad
      lotion
      unstable.obsidian
      unstable.openshot-qt
      unstable.parsec-bin
      qdirstat # graphical disk usage analyzer
      remmina # remote desktop client
      unstable.slack
      sublime-merge
      (unstable.unityhub.override {
        extraPkgs = ps: [
          ps.sqlite
          libtinfo-compat
          blip-caption
        ];
      })
      typora
      # Wrap zoom so its forked `zopen` browser-launcher helper inherits a sane
      # env. On Wayland, `zopen` aborts (SIGABRT in Qt) during the Google/SSO
      # OAuth browser hand-off; forcing XWayland (QT_QPA_PLATFORM=xcb) and giving
      # it an explicit BROWSER fixes the sign-in crash. See nixpkgs #69352/#75903.
      (unstable.symlinkJoin {
        name = "zoom-us-wrapped";
        paths = [ unstable.zoom-us ];
        nativeBuildInputs = [ unstable.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/zoom \
            --set QT_QPA_PLATFORM xcb \
            --set BROWSER zen
        '';
      })
    ];
  };
in
{
  imports = [
    ./audiomemo.nix
    ./flatpak.nix
  ];

  home.packages =
    lib.optionals pkgs.stdenv.hostPlatform.isx86_64 (lib.flatten (lib.attrValues packageGroups))
    ++ appImagePackages;
}
