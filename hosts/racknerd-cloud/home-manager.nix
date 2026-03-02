# This is your home-manager configuration file for headless servers
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../common/home
  ];

  # Disable fish-ai installation for headless server
  xdg.dataFile."fish-ai".enable = lib.mkForce false;
  home.activation.fishAiCleanup = lib.mkForce (lib.hm.dag.entryAnywhere "");

  # lorri for nix-shell
  services.lorri.enable = true;

  # gnupg gpg stuff
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
  };
}
