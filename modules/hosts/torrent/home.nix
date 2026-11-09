# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ inputs, ... }:
let
  inherit (inputs) dotfiles-assets;
in
{
  den.aspects.torrent.homeManager =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      initConfigAdditions = ''
        eval $(/opt/homebrew/bin/brew shellenv)
        fish_add_path -a /Applications/Obsidian.app/Contents/MacOS
      '';
      fonts = import ../../_data/fonts { inherit pkgs lib dotfiles-assets; };
    in
    {
      imports = [
        ./_packages
        ./_python.nix
      ];

      home.packages = [
        fonts.berkeley-mono-nerd-font
      ];

      home.sessionVariables = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };

      programs = {
        fish.interactiveShellInit = lib.strings.concatStrings [
          (import ../../home/fish/_init.nix { inherit pkgs config; }).interactiveShellInit
          initConfigAdditions
        ];
      };
    };
}
