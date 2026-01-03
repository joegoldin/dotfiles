{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.fish = {
    enable = true;
    interactiveShellInit = (import ./init.nix {inherit pkgs config;}).interactiveShellInit;
    functions = import ./functions.nix;
    plugins = (import ./plugins.nix {inherit pkgs;}).plugins;
    shellAbbrs = (import ./aliases.nix {inherit lib config;}).shellAbbrs;
    shellAliases = (import ./aliases.nix {inherit lib config;}).shellAliases;
  };

  programs.atuin = import ./atuin.nix {inherit pkgs config;};

  home.activation.fishAiPostInstall = lib.hm.dag.entryAfter ["installPackages"] ''
    export PATH="${lib.makeBinPath [pkgs.python3 pkgs.grc pkgs.git pkgs.uv]}:$PATH"
    echo "Running fish-ai installation..."
    run ${pkgs.fish}/bin/fish -c '_fish_ai_install'
  '';
}
