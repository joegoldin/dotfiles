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

  programs.git.extraConfig.gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";

  services.barrier.client.enable = true;
}
