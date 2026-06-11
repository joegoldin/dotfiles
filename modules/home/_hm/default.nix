# Shared home-manager baseline (was hosts/common/home/default.nix).
# The flake-input hm modules (audiomemo, attic-client, agent-skills) are
# wired per-host in modules/hosts/*/default.nix where `inputs` is in scope —
# imports here must stay arg-free so this file works as a plain module.
{
  config,
  username,
  homeDirectory,
  stateVersion,
  ...
}:
{
  imports = [
    ./fish
    ./packages
    ./gh.nix
    ./git.nix
    ./1password.nix
    ./attic.nix
    ./gpg.nix
    ./starship.nix
    ./claude
    ./antigravity
    ./codex
    ./mcp.nix
    ./notify.nix
    ./bin
  ];

  # Enable home-manager
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home = {
    inherit stateVersion username homeDirectory;

    # copy xdg config files
    file."${config.xdg.configHome}/." = {
      source = ../../_data/dotconfig;
      recursive = true;
    };

  };
}
