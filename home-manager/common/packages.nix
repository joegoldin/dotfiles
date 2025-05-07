{
  pkgs,
  lib,
  config,
  ...
}: let
  unstable = pkgs.unstable;
  nodeModule = import ./node {inherit pkgs lib unstable config;};
  pythonModule = import ./python {inherit pkgs lib unstable;};

  # System-specific package sets
  nixosPackages = with pkgs;
    lib.optionals (pkgs.stdenv.hostPlatform.isx86_64) [
      unstable.cloudflared
      unstable.code-cursor
      unstable.davinci-resolve
      unstable.discord
      inotify-tools
      unstable.jellyfin-media-player
      unstable.obsidian
      unstable.parsec-bin
      unstable.slack
      unstable.steam
      unstable.streamcontroller
      sublime-merge
      unstable.tailscale
      vlc
      unstable.zoom-us
    ];

  macosPackages = with pkgs; [
    shopt-script
    iterm2-terminal-integration
  ];

  wslPackages = with pkgs; [
  ];

  # Common packages for all systems
  commonPackages = with pkgs;
    lib.flatten [
      act
      pkgs.unstable.aider-chat
      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      awscli2
      bfg-repo-cleaner
      bun
      cachix
      caddy
      clojure
      comma
      coreutils
      cowsay
      unstable.devenv
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
      leiningen
      nix
      nmap
      nnn # terminal file manager
      nix-your-shell
      nodeModule.packages
      openring
      p7zip
      pinentry-curses
      playwright-driver
      playwright-driver.browsers
      pre-commit
      pueue
      pythonModule.packages
      ripgrep # recursively searches directories for a regex pattern
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
      zlib
      zstd
    ];
in {
  home.packages =
    commonPackages
    ++ (
      if pkgs.stdenv.isLinux && !(lib.hasAttr "wsl" config && config.wsl.enable)
      then nixosPackages
      else []
    )
    ++ (
      if pkgs.stdenv.isDarwin
      then macosPackages
      else []
    )
    ++ (
      if lib.hasAttr "wsl" config && config.wsl.enable
      then wslPackages
      else []
    );

  #  home.activation.nodePreInstall = nodeModule.nodePreInstall;
  #  home.activation.nodeSetupGlobal = nodeModule.nodeSetupGlobal;
  #  home.activation.nodePostInstall = nodeModule.nodePostInstall;
  home.activation.pythonPostInstall = pythonModule.pythonPostInstall;

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
