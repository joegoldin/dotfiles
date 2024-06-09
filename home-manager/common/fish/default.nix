{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.fish = {
    enable = true;
    interactiveShellInit = (import ./init.nix {inherit pkgs;}).interactiveShellInit;
    functions = import ./functions.nix;
    plugins = (import ./plugins.nix {inherit pkgs;}).plugins;
    shellAbbrs = (import ./aliases.nix {inherit lib config;}).shellAbbrs;
    shellAliases = (import ./aliases.nix {inherit lib config;}).shellAliases;
  };
}
