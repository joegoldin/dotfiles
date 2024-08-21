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
    eval $(/opt/homebrew/bin/brew shellenv)
    source ${pkgs.iterm2-terminal-integration}/bin/iterm2_shell_integration.fish
  '';
in {
  imports = [
    ../common
  ];

  home.packages =
    (import ../common/packages.nix {inherit pkgs lib;}).home.packages
    ++ (with pkgs; [
      # macos only packages
      shopt-script
      iterm2-terminal-integration
      clai-go
    ]);
  programs.fish.interactiveShellInit = lib.strings.concatStrings [
    (import ../common/fish/init.nix {inherit pkgs;}).interactiveShellInit
    initConfigAdditions
  ];

  programs.git.extraConfig.gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";

  programs.ssh = {
    enable = true;
    matchBlocks = {
      # default = {
      #   hostname = "*";
      # };
    };
    extraConfig = lib.mkOrder 100 ''
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    '';
  };
}
