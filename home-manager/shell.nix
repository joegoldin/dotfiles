{ pkgs, lib, config, ... }: 
{
  programs.fish = {
    enable = true;
    interactiveShellInit = (import ./fish/init.nix {inherit pkgs;}).interactiveShellInit;
    functions = (import ./fish/functions.nix);
    plugins = (import ./fish/plugins.nix {inherit pkgs;}).plugins;
    shellAbbrs = (import ./fish/aliases.nix {inherit lib config;}).shellAbbrs;
    shellAliases = (import ./fish/aliases.nix {inherit lib config;}).shellAliases;
  };
}
