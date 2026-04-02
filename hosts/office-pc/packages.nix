{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) unstable;
  streamcontroller = import ../common/system/streamcontroller.nix { inherit pkgs; };
in
{
  home.packages =
    with pkgs;
    lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      claude-container
      docker-buildx
      unstable.ffmpeg
      inotify-tools
      localsend
      mpv
      nvtopPackages.amd
      pulseaudio # pactl required by pulsemeeter's pmctl script
      unstable.pulsemeeter
      unstable.pulsemixer
      rclone
      rocmPackages.amdsmi
      rocmPackages.rocminfo
      streamcontroller.package
      ungoogled-chromium
      unstable.cloudflared
      unstable.tailscale
      unstable.vllm
      wl-clipboard
      xclip
    ];

  xdg.configFile."autostart/StreamController.desktop".text = streamcontroller.autostartDesktopEntry;
}
