{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) unstable;
  goModule = import ../common/home/go.nix { inherit pkgs lib; };
  appImagePackages = import ../common/home/appimages.nix { inherit pkgs; };
  streamcontroller = import ../common/system/streamcontroller.nix { inherit pkgs; };
in
{
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
      unstable.cloudflared
      desktop-wakatime
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
      unstable.umu-launcher
      (unstable.unityhub.override {
        extraPkgs = ps: [
          ps.sqlite
          blip-caption
        ];
      })
      mpv
      nvtopPackages.amd
      unstable.vllm-rocm
      wl-clipboard
      xclip
      unstable.zoom-us
    ]
    ++ appImagePackages;

  xdg.configFile."autostart/StreamController.desktop".text = streamcontroller.autostartDesktopEntry;

  # PulseAudio device names; merged with the common audiomemo settings in
  # hosts/common/home/packages.nix.
  programs.audiomemo.settings = {
    record.device = "mic";
    devices = {
      mic = "alsa_input.usb-MOTU_M2_M20000044767-00.HiFi__Mic1__source";
      speakers = "alsa_output.usb-MOTU_M2_M20000044767-00.HiFi__Line1__sink.monitor";
    };
    device_groups.combo = [
      "mic"
      "speakers"
    ];
  };

  # Flatpak packages (installed via nix-flatpak)
  services.flatpak = {
    enable = true;
    packages = [ "com.bambulab.BambuStudio" ];
    update.onActivation = true;
  };
}
