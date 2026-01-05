{
  pkgs,
  lib,
  config,
  affinity-nix,
  nix-ai-tools,
  ...
}: let
  unstable = pkgs.unstable;
  pythonModule = import ./python {inherit pkgs lib unstable;};
  appImagePackages = import ./appimages.nix {inherit pkgs;};
  cargoModule = import ./cargo.nix {inherit pkgs lib;};
  goModule = import ./go.nix {inherit pkgs lib;};

  # System-specific package sets
  nixosPackages = with pkgs;
    lib.optionals (pkgs.stdenv.hostPlatform.isx86_64) [
      # affinity-nix.packages.x86_64-linux.photo
      # unstable.android-studio-full
      unstable.cloudflared
      # nix-ai-tools.packages.x86_64-linux.codex # disabled after s1ngularity attack
      #      unstable.davinci-resolve
      unstable.discord
      unstable.dumbpipe
      # extraterm
      inotify-tools
      # unstable.jellyfin-media-player
      #      cargoModule.packages.litra
      #      cargoModule.packages.litra-autotoggle
      unstable.obsidian
      unstable.parsec-bin
      reptyr
      unstable.slack
      unstable.steam
      unstable.streamcontroller
      sublime-merge
      unstable.tailscale
      ungoogled-chromium
      vlc
      unstable.zoom-us
    ]
    ++ appImagePackages;

  macosPackages = with pkgs; [
    shopt-script
    iterm2-terminal-integration
  ];

  wslPackages = with pkgs; [
    openssl
    openssl.dev
    wsl-open
  ];

  # Common packages for all systems
  commonPackages = with pkgs;
    lib.flatten [
      act
      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      unstable.asciinema_3
      awscli2
      bc
      bfg-repo-cleaner
      bun
      cachix
      caddy
      unstable.claude-code
      goModule.packages.claude-squad
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
      ghostty
      git
      gitleaks
      git-stack
      git-worktree-switcher
      glow # markdown previewer in terminal
      gnumake
      gnupg
      gnused
      gnutar
      grc
      unstable.gum
      httpie
      helm-with-plugins
      helm-ls
      helm-docs
      helmfile-with-plugins
      unstable.hugo
      imagemagick
      jq # A lightweight and flexible command-line JSON processor
      k9s
      kubectl
      kubectx
      kubent
      lazydocker
      leiningen
      nix
      nix-your-shell
      nmap
      nnn # terminal file manager
      unstable.marp-cli
      openring
      p7zip
      pinentry-curses
      pipenv
      playwright-driver
      playwright-driver.browsers
      popeye
      pre-commit
      pueue
      pythonModule.packages
      ripgrep # recursively searches directories for a regex pattern
      # rustup
      socat # replacement of openbsd-netcat
      stripe-cli
      tesseract
      tmux
      tree
      trippy
      typescript
      unstable.just
      unzip
      uv
      watch
      wget
      which
      xdg-utils
      xz
      unstable.yarn-berry_3
      yq-go # yaml processer https://github.com/mikefarah/yq
      yt-dlp
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
