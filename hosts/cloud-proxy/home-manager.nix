{
  pkgs,
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
    ../common/home/gpg.nix
    ../common/home/starship.nix
  ];

  programs.home-manager.enable = true;
  systemd.user.startServices = "sd-switch";

  home = {
    inherit stateVersion username homeDirectory;

    packages = with pkgs; [
      coreutils
      direnv
      file
      fish
      fzf
      gawk
      git
      gnumake
      gnupg
      gnused
      gnutar
      grc
      httpie
      jq
      nix-output-monitor
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
}
