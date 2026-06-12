# Packages unique to joe-desktop; shared linux-workstation packages live in
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

  packageGroups = with pkgs; {
    cli = [
      goModule.packages.claude-squad
      blip-caption
      bubblewrap
      gcc15
      glibc
      unstable.jdk25_headless
      # cargoModule.packages.litra
      # cargoModule.packages.litra-autotoggle
      libgcc
      reptyr
      rocmPackages.rocm-smi
    ];

    gui = [
      affinity-v3
      cameractrls-gtk3
      claude-desktop-fhs
      unstable.darktable
      # unstable.davinci-resolve
      unstable.discord
      # hyprwhspr
      unstable.jellyfin-desktop
      lotion
      unstable.obsidian
      unstable.parsec-bin
      qdirstat # graphical disk usage analyzer
      unstable.slack
      sublime-merge
      (unstable.unityhub.override {
        extraPkgs = ps: [
          ps.sqlite
          blip-caption
        ];
      })
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
