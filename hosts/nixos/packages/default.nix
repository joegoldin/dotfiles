# Linux-ONLY home packages — only things tied to this platform belong here
# (ROCm/AMD tooling, linux desktop apps, audio plumbing, X/Wayland helpers).
# Anything cross-platform goes in hosts/common/home/packages/workstation.nix
# (workstations) or hosts/common/home/packages/default.nix (all hosts).
{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) unstable;
  goModule = import ../../common/home/go.nix { inherit pkgs lib; };
  appImagePackages = import ../../common/home/appimages.nix { inherit pkgs; };

  packageGroups = with pkgs; {
    cli = [
      goModule.packages.claude-squad
      blip-caption
      bubblewrap
      docker-buildx
      gcc15
      glibc
      inotify-tools
      unstable.jdk25_headless
      # cargoModule.packages.litra
      # cargoModule.packages.litra-autotoggle
      libgcc
      nvtopPackages.amd
      pulseaudio # pactl required by pulsemeeter's pmctl script
      unstable.pulsemixer
      reptyr
      rocmPackages.amdsmi
      rocmPackages.rocminfo
      rocmPackages.rocm-smi
      unstable.tailscale
      unstable.umu-launcher
      # unstable.vllm-rocm # temporarily disabled — 15h build
      wl-clipboard
      xclip
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
      localsend
      lotion
      unstable.obsidian
      unstable.parsec-bin
      unstable.pulsemeeter
      qdirstat # graphical disk usage analyzer
      unstable.slack
      sublime-merge
      ungoogled-chromium
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
    ./streamcontroller.nix
  ];

  home.packages =
    lib.optionals pkgs.stdenv.hostPlatform.isx86_64 (lib.flatten (lib.attrValues packageGroups))
    ++ appImagePackages;
}
