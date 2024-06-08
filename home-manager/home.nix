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
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    ./shell.nix
    ./core.nix
    ./git.nix
    ./starship.nix

    # inputs._1password-shell-plugins.hmModules.default
  ];

  # Enable home-manager
  programs.home-manager.enable = true;
  
  # programs._1password-shell-plugins = {
  #   # enable 1Password shell plugins for bash, zsh, and fish shell
  #   enable = true;
  #   # the specified packages as well as 1Password CLI will be
  #   # automatically installed and configured to use shell plugins
  #   plugins = with pkgs; [ gh awscli2 ];
  # };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home = {
    username = username;
    homeDirectory = homeDirectory;
    stateVersion = "24.05";
  };
}
