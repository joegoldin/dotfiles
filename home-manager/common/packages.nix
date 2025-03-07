{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs;
    lib.flatten [
      act
      pkgs.unstable.aider-chat
      nix-your-shell
      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      awscli2
      bfg-repo-cleaner
      cachix
      caddy
      comma
      coreutils
      cowsay
      devenv
      direnv
      elixir_1_18
      erlang_27
      file
      fish
      flyctl
      fzf # A command-line fuzzy finder
      gawk
      gh
      git
      gitleaks
      glow # markdown previewer in terminal
      gnumake
      gnupg
      gnused
      gnutar
      grc
      httpie
      helm-with-plugins
      helmfile-with-plugins
      unstable.hugo
      imagemagick
      jq # A lightweight and flexible command-line JSON processor
      k9s
      kubectl
      lazydocker
      nix
      nmap
      nnn # terminal file manager
      (import ./node.nix {inherit pkgs lib;})
      openring
      p7zip
      pinentry-curses
      pre-commit
      pueue
      (import ./python {inherit pkgs lib unstable;})
      ripgrep # recursivel searches directories for a regex pattern
      rustup
      socat # replacement of openbsd-netcat
      tesseract
      tree
      unstable.just
      unzip
      wget
      which
      xz
      yq-go # yaml processer https://github.com/mikefarah/yq
      zellij
      zip
      zstd
    ];

  programs = {
    # skim provides a single executable: sk.
    # Basically anywhere you would want to use grep, try sk instead.
    skim = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
    };

    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    zellij = {
      enable = true;
      enableFishIntegration = false;
      enableBashIntegration = false;
      enableZshIntegration = false;
    };
  };
}
