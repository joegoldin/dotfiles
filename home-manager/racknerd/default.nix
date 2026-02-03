# This is your home-manager configuration file for headless servers
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  username,
  homeDirectory,
  stateVersion,
  ...
}: {
  imports = [
    ../common
  ];

  # Disable ghostty for headless server
  programs.ghostty.enable = lib.mkForce false;

  # lorri for nix-shell
  services.lorri.enable = true;

  # gnupg gpg stuff
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
  };
}
