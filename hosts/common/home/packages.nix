{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) unstable;
  pythonModule = import ./python { inherit pkgs lib unstable; };
  spritesModule = import ./sprites.nix { inherit pkgs lib; };

  # Common packages for all systems
  commonPackages =
    with pkgs;
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
      # claude-code is provided by ./claude module with plugins
      clojure
      codex
      comma
      happy-cli
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
      # gh is managed by programs.gh in gh.nix
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
      nil
      nix
      nix-your-shell
      nixd
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
      spritesModule.packages.sprite
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
in
{
  home.packages = commonPackages;

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
