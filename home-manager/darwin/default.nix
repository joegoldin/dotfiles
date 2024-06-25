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
}: let
  initConfigAdditions = ''
    source ${pkgs.iterm2-terminal-integration}/bin/iterm2_shell_integration.fish
  '';
in {
  imports = [
    ../common
  ];

  home.packages =
    (import ../common/packages.nix {inherit pkgs;}).home.packages
    ++ (with pkgs; [
      shopt-script
      iterm2-terminal-integration
      # brewCasks.1password-cli
      # brewCasks.stats
      # brewCasks.android-platform-tools
      # brewCasks.flameshot
      # brewCasks.michaelvillar-timer
      # brewCasks.modern-csv
      # brewCasks.ngrok
      # brewCasks.sanesidebuttons
      # brewCasks.tomatobar
    ]);
  programs.fish.interactiveShellInit = lib.strings.concatStrings [
    (import ../common/fish/init.nix {inherit pkgs;}).interactiveShellInit
    initConfigAdditions
  ];

  programs.git.extraConfig.gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
}
