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
    ../common/cursor-linux-server.nix
  ];

  # lorri for nix-shell
  services.lorri.enable = true;
}
