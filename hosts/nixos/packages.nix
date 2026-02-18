{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) unstable;
  goModule = import ../common/home/go.nix { inherit pkgs lib; };
  appImagePackages = import ../common/home/appimages.nix { inherit pkgs; };
in
{
  home.packages =
    with pkgs;
    lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      # affinity-nix.packages.x86_64-linux.photo
      # unstable.android-studio-full
      unstable.calcurse
      goModule.packages.claude-squad
      claude-container
      claude-desktop
      unstable.cloudflared
      #      unstable.davinci-resolve
      unstable.discord
      unstable.dumbpipe
      # extraterm
      # ghostty is managed by programs.ghostty in ghostty.nix
      inotify-tools
      # unstable.jellyfin-media-player
      #      cargoModule.packages.litra
      #      cargoModule.packages.litra-autotoggle
      lotion
      unstable.obsidian
      unstable.parsec-bin
      pulseaudio # pactl required by pulsemeeter's pmctl script
      unstable.pulsemeeter
      unstable.pulsemixer
      reptyr
      unstable.slack
      unstable.streamcontroller
      sublime-merge
      unstable.tailscale
      ungoogled-chromium
      vlc
      unstable.vllm
      unstable.zoom-us
    ]
    ++ appImagePackages;
}
