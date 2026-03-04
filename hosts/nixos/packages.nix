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
      unstable.android-studio-full
      unstable.calcurse
      chromedriver
      goModule.packages.claude-squad
      claude-desktop-fhs
      unstable.cloudflared
      unstable.darktable
      unstable.davinci-resolve
      unstable.discord
      docker-buildx
      unstable.dumbpipe
      inotify-tools
      unstable.jellyfin-desktop
      # cargoModule.packages.litra
      # cargoModule.packages.litra-autotoggle
      localsend
      lotion
      unstable.obsidian
      unstable.parsec-bin
      pulseaudio # pactl required by pulsemeeter's pmctl script
      unstable.pulsemeeter
      unstable.pulsemixer
      reptyr
      unstable.slack
      streamcontroller.package
      sublime-merge
      unstable.tailscale
      ungoogled-chromium
      mpv
      # unstable.vllm # disabled: torchaudio/compressed-tensors build failures in nixpkgs-unstable
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
