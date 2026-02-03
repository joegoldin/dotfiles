# This is your home-manager configuration file for headless servers
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
  affinity-nix,
  nix-ai-tools,
  ...
}: {
  imports = [
    # Import only server-relevant configs from common
    ../common/fish
    (import ../common/packages.nix {inherit pkgs lib config affinity-nix nix-ai-tools;})
    ../common/git.nix
    # Skip ghostty.nix - not needed for headless server
    ../common/starship.nix
    ../common/claude
  ];

  # Enable home-manager
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = stateVersion;
  home.username = username;
  home.homeDirectory = homeDirectory;

  # lorri for nix-shell
  services.lorri.enable = true;

  # gnupg gpg stuff
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
  };
}
