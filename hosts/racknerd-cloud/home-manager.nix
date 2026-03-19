# Lightweight home-manager config for headless server
# Does NOT import ../common/home (too large for VPS disk)
# Instead, imports only the modules a server needs
{
  lib,
  pkgs,
  inputs,
  username,
  homeDirectory,
  stateVersion,
  ...
}:
{
  imports = [
    ../common/home/fish
    ../common/home/gh.nix
    ../common/home/git.nix
    ../common/home/starship.nix
  ];

  programs.home-manager.enable = true;
  systemd.user.startServices = "sd-switch";

  home = {
    inherit stateVersion username homeDirectory;

    packages = with pkgs; [
      comma
      coreutils
      direnv
      dua
      file
      fish
      fzf
      gawk
      git
      gnumake
      gnupg
      gnused
      gnutar
      httpie
      jq
      lazydocker
      nix-output-monitor
      nix-your-shell
      nixfmt
      ripgrep
      tmux
      tree
      unstable.just
      unzip
      watch
      wget
      which
      yq-go
      zip
      zstd
    ];
  };

  # lorri for nix-shell
  services.lorri.enable = true;

  # gnupg gpg stuff
  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
  };
}
