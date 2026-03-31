# hosts/steamdeck/packages.nix
# Lean package set for Steam Deck — essentials only
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Essentials
    ripgrep
    fzf
    jq
    tree
    wget
    curl
    unzip
    zip

    # System
    htop
    pciutils
    usbutils

    # Nix
    nh
    nix-output-monitor
    nixfmt
    comma
  ];
}
