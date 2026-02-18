{ pkgs, ... }:
{
  home.packages = with pkgs; [
    shopt-script
    iterm2-terminal-integration
  ];
}
