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
  dotfiles-assets,
  ...
}: let
  initConfigAdditions = ''
    eval $(/opt/homebrew/bin/brew shellenv)
    if test "$TERM_PROGRAM" = "iTerm.app"
      source ${pkgs.iterm2-terminal-integration}/bin/iterm2_shell_integration.fish
    end
    fish_add_path -a /Applications/Obsidian.app/Contents/MacOS
  '';
  fonts = import ../../common/system/fonts {inherit pkgs lib dotfiles-assets;};
in {
  imports = [
    ../../common/home
  ];

  home.packages = with pkgs; [
    fonts.berkeley-mono-nerd-font
  ];

  home.sessionVariables = {
    CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
  };

  programs.fish.interactiveShellInit = lib.strings.concatStrings [
    (import ../../common/home/fish/init.nix {inherit pkgs config;}).interactiveShellInit
    initConfigAdditions
  ];

  programs.git.settings.gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        identityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
      };
    };
    extraConfig = lib.mkOrder 100 ''
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    '';
  };
}
