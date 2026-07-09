# hosts/steamdeck/packages.nix
# Lean package set for Steam Deck; essentials only
{ pkgs, ... }:
{
  # direnv with automatic fish/bash hooking (the fish aspect no longer
  # hooks direnv manually).
  programs.direnv.enable = true;

  home.packages = with pkgs; [
    grc
    ripgrep
    fzf
    jq
    tree
    wget
    curl
    unzip
    zip
    htop
    pciutils
    usbutils
    nix-output-monitor
    nixfmt
    unstable.ffmpeg
    unstable.just
    unstable.umu-launcher
  ];
}
