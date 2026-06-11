# hosts/steamdeck/packages.nix
# Lean package set for Steam Deck — essentials only
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    direnv
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
