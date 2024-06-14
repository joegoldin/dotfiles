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
  ];

  home.packages =
    (import ../common/packages.nix {inherit pkgs;}).home.packages
    ++ (with pkgs; [
      shopt-script
    ]);

  programs.git.extraConfig.gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
}
