{pkgs, ...}: {
  ##########################################################################
  #
  #  Install all apps and packages here.
  #
  #  NOTE: Your can find all available options in:
  #    https://daiderd.com/nix-darwin/manual/index.html
  #
  #
  ##########################################################################

  environment.variables.EDITOR = "cursor";

  # TODO To make this work, homebrew need to be installed manually, see https://brew.sh
  #
  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      # 'zap': uninstalls all formulae(and related files) not listed here.
      cleanup = "zap";
    };

    # Applications to install from Mac App Store using mas.
    # You need to install all these Apps manually first so that your apple account have records for them.
    # otherwise Apple Store will refuse to install them.
    # For details, see https://github.com/mas-cli/mas
    masApps = {
      # Xcode = 497799835; // using the beta from apple dev
      JumpDesktop = 524141863;
      Flycut = 442160987;
      RosettaStone = 1476088902;
      Amphetamine = 937984704;
      TestFlight = 899247664;
      Tailscale = 1475387142;
      Barbee = 1548711022;
      Peek = 1554235898;
      Patterns = 429449079;
      RocketSim = 1504940162;
    };

    taps = [
      "homebrew/services"
      "argoproj/tap"
      "assemblyai/assemblyai"
      "derailed/k9s"
      "homebrew/bundle"
      "homebrew/services"
      "ibigio/tap"
      "saulpw/vd"
      "schappim/ocr"
      "txn2/tap"
      "versent/taps"
      "blacktop/tap"
    ];

    # `brew install`
    brews = [
      "act"
      "asciinema"
      "asdf"
      "assemblyai/assemblyai/assemblyai"
      "autoconf@2.69"
      "awscli"
      "cloudflared"
      "cmake"
      "croc"
      "derailed/k9s/k9s"
      "dive"
      "direnv"
      "docutils"
      "entr"
      "expat"
      "flyctl"
      "fontforge"
      "fx"
      "gh"
      "ghostscript"
      "git-lfs"
      "glow"
      "gum"
      "helmfile"
      "htop"
      "httpie"
      "jenv"
      "jj"
      "keyring"
      "kubectx"
      "lporg"
      "marp-cli"
      "mas"
      "mysql"
      "neofetch"
      "okteto"
      "ollama"
      "pidgin"
      "portaudio"
      "profanity"
      "protobuf"
      "redis"
      "ruby"
      "rust"
      "saml2aws"
      "saulpw/vd/visidata"
      "schappim/ocr/ocr"
      "scrcpy"
      "stern"
      "swift-format"
      "tailspin"
      "tcl-tk"
      "telnet"
      "terraform"
      "the_silver_searcher"
      "timg"
      "txn2/tap/kubefwd"
      "universal-ctags"
      "virtualenv"
      "watchman"
      "wget"
      "yarn"
    ];

    # `brew install --cask`
    casks = [
      "1password"
      "1password-cli"
      "android-platform-tools"
      "arc"
      "barrier"
      "bruno"
      "cursor"
      "daisydisk"
      "discord"
      "docker"
      "figma"
      "google-chrome"
      "iterm2"
      "itermai"
      "logseq"
      "lulu"
      "mac-mouse-fix"
      "michaelvillar-timer"
      "modern-csv"
      "monodraw"
      "notion"
      "postico"
      "rectangle-pro"
      "roon"
      "soundsource"
      "shottr"
      "slack"
      "stats"
      "steam"
      "sublime-merge"
      "sublime-text"
      "tomatobar"
      "zoom"
    ];
  };
}
