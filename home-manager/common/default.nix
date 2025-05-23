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
  affinity-nix,
  claude-desktop,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    ./fish
    (import ./packages.nix {inherit pkgs lib config affinity-nix claude-desktop;})
    ./git.nix
    ./starship.nix
  ];

  # Enable home-manager
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = stateVersion;
  home.username = username;
  home.homeDirectory = homeDirectory;

  # copy xdg config files
  home.file."${config.xdg.configHome}/." = {
    source = ../../environments/common/dotconfig;
    recursive = true;
  };
}
