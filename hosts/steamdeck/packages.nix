# hosts/steamdeck/packages.nix
# Lean package set for Steam Deck — essentials only
{ pkgs, ... }:
{
  home.packages = with pkgs; [
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
    comma
    unstable.just
  ];
}
