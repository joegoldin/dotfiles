{
  pkgs,
  lib,
  affinity-nix,
  ...
}:
let
  inherit (pkgs) unstable;
  goModule = import ../common/home/go.nix { inherit pkgs lib; };
  appImagePackages = import ../common/home/appimages.nix { inherit pkgs; };
  streamcontroller = import ./streamcontroller.nix { inherit pkgs; };
in
{
  home.packages =
    with pkgs;
    lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      affinity-nix.packages.x86_64-linux.v3
      unstable.calcurse
      chromedriver
      goModule.packages.claude-squad
      claude-desktop-fhs
      unstable.cloudflared
      unstable.darktable
      # unstable.davinci-resolve
      unstable.discord
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
      rclone
      reptyr
      rocmPackages.amdsmi
      rocmPackages.rocminfo
      unstable.slack
      rocmPackages.rocm-smi
      streamcontroller.package
      sublime-merge
      unstable.tailscale
      ungoogled-chromium
      mpv
      nvtopPackages.amd
      unstable.vllm
      wl-clipboard
      xclip
    ]
    ++ appImagePackages;

  xdg.configFile."autostart/StreamController.desktop".text = streamcontroller.autostartDesktopEntry;

  # Flatpak packages (installed via nix-flatpak)
  services.flatpak = {
    enable = true;
    packages = [
      "us.zoom.Zoom"
    ];
  };
}
