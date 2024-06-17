{pkgs, ...}: {
  home.packages = with pkgs; [
    # TODO order this list
    coreutils
    nnn # terminal file manager
    nix
    cachix
    direnv
    devenv
    unstable.just
    pueue
    fish
    pre-commit
    bfg-repo-cleaner
    gitleaks

    clai-go # from go package via overlay

    git
    gh
    awscli2

    zellij

    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    ripgrep # recursivel searches directories for a regex pattern
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processer https://github.com/mikefarah/yq
    fzf # A command-line fuzzy finder
    grc
    wget

    kubectl

    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing

    # misc
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    caddy
    gnupg

    any-nix-shell
    comma
    noseyparker

    # productivity
    glow # markdown previewer in terminal
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
