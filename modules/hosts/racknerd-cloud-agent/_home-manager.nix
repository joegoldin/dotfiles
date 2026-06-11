# Lightweight home-manager config for headless server
# Does NOT import ../../home/_hm (too large for VPS disk)
# Instead, imports only the modules a server needs
{
  pkgs,
  username,
  homeDirectory,
  stateVersion,
  ...
}:
{
  imports = [
    ../../home/_hm/fish
    ../../home/_hm/gh.nix
    ../../home/_hm/git.nix
    ../../home/_hm/gpg.nix
    ../../home/_hm/starship.nix
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

}
