{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) unstable;
  goModule = import ../../common/home/go.nix { inherit pkgs lib; };
  appImagePackages = import ../../common/home/appimages.nix { inherit pkgs; };
in
{
  imports = [
    ./audiomemo.nix
    ./flatpak.nix
    ./streamcontroller.nix
  ];

  home.packages =
    with pkgs;
    lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      affinity-v3
      unstable.calcurse
      cameractrls-gtk3
      chromedriver
      goModule.packages.claude-squad
      claude-container
      claude-desktop-fhs
      blip-caption
      bubblewrap
      unstable.darktable
      # unstable.davinci-resolve
      unstable.discord
      unstable.ffmpeg
      # hyprwhspr
      docker-buildx
      unstable.dumbpipe
      unstable.gradle_9
      gcc15
      glibc
      inotify-tools
      unstable.jdk25_headless
      unstable.jellyfin-desktop
      # cargoModule.packages.litra
      # cargoModule.packages.litra-autotoggle
      libgcc
      localsend
      lotion
      unstable.maven
      unstable.obsidian
      unstable.parsec-bin
      pulseaudio # pactl required by pulsemeeter's pmctl script
      unstable.pulsemeeter
      unstable.pulsemixer
      qdirstat # graphical disk usage analyzer
      rclone
      reptyr
      rocmPackages.amdsmi
      rocmPackages.rocminfo
      unstable.slack
      rocmPackages.rocm-smi
      sublime-merge
      unstable.tailscale
      ungoogled-chromium
      unstable.umu-launcher
      (unstable.unityhub.override {
        extraPkgs = ps: [
          ps.sqlite
          blip-caption
        ];
      })
      mpv
      nvtopPackages.amd
      # unstable.vllm-rocm # temporarily disabled — 15h build
      wl-clipboard
      xclip
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
    ]
    ++ appImagePackages;
}
