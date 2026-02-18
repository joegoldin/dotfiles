# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  lib,
  config,
  pkgs,
  username,
  homeDirectory,
  stateVersion,
  ...
}:
{
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    ./fish
    (import ./packages.nix { inherit pkgs lib config; })
    ./gh.nix
    ./git.nix
    ./starship.nix
    ./claude
  ];

  # Enable home-manager
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home = {
    inherit stateVersion username homeDirectory;

    # copy xdg config files
    file."${config.xdg.configHome}/." = {
      source = ../system/dotconfig;
      recursive = true;
    };

    # symlink bin folder
    file.".local/bin" = {
      source = ../../../bin;
      recursive = true;
    };
  };
}
