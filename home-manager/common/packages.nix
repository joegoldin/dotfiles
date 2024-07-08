{pkgs, ...}: {
  home.packages = with pkgs; [
    any-nix-shell
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    awscli2
    bfg-repo-cleaner
    cachix
    caddy
    clai-go # from go package via overlay
    comma
    coreutils
    cowsay
    devenv
    direnv
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
    jq # A lightweight and flexible command-line JSON processor
    kubectl
    nix
    nmap
    nnn # terminal file manager
    p7zip
    pre-commit
    pueue
    ripgrep # recursivel searches directories for a regex pattern
    socat # replacement of openbsd-netcat
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
