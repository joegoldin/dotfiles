{ pkgs, ... }: {

  ##########################################################################
  # 
  #  Install all apps and packages here.
  #
  #  NOTE: Your can find all available options in:
  #    https://daiderd.com/nix-darwin/manual/index.html
  # 
  # TODO Fell free to modify this file to fit your needs.
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
      # TODO Feel free to add your favorite apps here.
      Xcode = 497799835;
      JumpDesktop = 524141863;
      TheUnarchiver = 425424353;
      Magnet = 441258766;
      Flycut = 442160987;
      RosettaStone = 1476088902;
      OnePassword = 1333542190;
    };

    taps = [
      "homebrew/services"
      "argoproj/tap"
      "assemblyai/assemblyai"
      "cloudflare/cloudflare"
      "derailed/k9s"
      "homebrew/bundle"
      "homebrew/services"
      "ibigio/tap"
      "saulpw/vd"
      "schappim/ocr"
      "txn2/tap"
      "versent/taps"
    ];

    # `brew install`
    # TODO Feel free to add your favorite apps here.
    brews = [
      "act"
      "asciinema"
      "asdf"
      "assemblyai/assemblyai/assemblyai"
      "autoconf@2.69"
      "awscli"
      "cloudflare/cloudflare/cloudflared"
      "cmake"
      "croc"
      "derailed/k9s/k9s"
      "dive"
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
    # TODO Feel free to add your favorite apps here.
    casks = [
      "arc"
      "google-chrome"
      
      "cursor"

      "slack"
      "discord"

      "anki"
      "stats"


      "android-platform-tools"
      "bruno"
      "flameshot"
      "graphql-playground"
      "jordanbaird-ice"
      "michaelvillar-timer"
      "modern-csv"
      "ngrok"
      "sanesidebuttons"
      "tomatobar"
    ];
  };
}
