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

  home.packages = (import ../common/packages.nix {inherit pkgs;}).home.packages ++ (with pkgs; [
    # nixos only packages
  ]);

  # lorri for nix-shell
  services.lorri.enable = true;
}
