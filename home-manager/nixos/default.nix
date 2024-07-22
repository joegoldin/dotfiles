# This is your home-manager configuration file
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
    ../common/cursor-server-linux.nix
  ];

  home.packages =
    (import ../common/packages.nix {inherit pkgs;}).home.packages
    ++ (with pkgs; [
      # nixos only packages
      tailscale
    ]);

  # lorri for nix-shell
  services.lorri.enable = true;

  # gnupg gpg stuff
  services.gnome-keyring.enable = true;
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
  };
}
