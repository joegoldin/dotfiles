{
  pkgs,
  lib,
  ...
}: let
  unstable = pkgs.unstable;
  goModule = import ../common/home/go.nix {inherit pkgs lib;};
  appImagePackages = import ../common/home/appimages.nix {inherit pkgs;};
in {
  home.packages = with pkgs;
    lib.optionals (pkgs.stdenv.hostPlatform.isx86_64) [
      # affinity-nix.packages.x86_64-linux.photo
      # unstable.android-studio-full
      goModule.packages.claude-squad
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
      unstable.obsidian
      unstable.parsec-bin
      unstable.pulsemixer
      reptyr
      unstable.slack
      unstable.steam
      unstable.streamcontroller
      sublime-merge
      unstable.tailscale
      ungoogled-chromium
      vlc
      unstable.zed-editor
      unstable.zoom-us
    ]
    ++ appImagePackages;
}
