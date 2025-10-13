{
  inputs,
  config,
  pkgs,
  username,
  ...
}: {
  nix-homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = true;

    # User owning the Homebrew prefix
    user = username;

    # Automatically migrate existing Homebrew installations
    autoMigrate = true;

    # Declarative tap management
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/homebrew-services" = inputs.homebrew-services;
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
      "argoproj/homebrew-tap" = inputs.homebrew-argoproj;
      "assemblyai/homebrew-assemblyai" = inputs.homebrew-assemblyai;
      "derailed/homebrew-k9s" = inputs.homebrew-k9s;
      "ibigio/homebrew-tap" = inputs.homebrew-ibigio;
      "saulpw/homebrew-vd" = inputs.homebrew-vd;
      "schappim/homebrew-ocr" = inputs.homebrew-ocr;
      "skiptools/homebrew-skip" = inputs.homebrew-skip;
      "txn2/homebrew-tap" = inputs.homebrew-txn2;
      "versent/homebrew-taps" = inputs.homebrew-versent;
      "blacktop/homebrew-tap" = inputs.homebrew-blacktop;
      "cirruslabs/homebrew-cli" = inputs.homebrew-cirruslabs;
      "neilberkman/homebrew-clippy" = inputs.homebrew-neilberkman;
    };

    # Enable fully-declarative tap management
    # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
    mutableTaps = false;
  };

  # Homebrew configuration
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      # 'zap': uninstalls all formulae(and related files) not listed here.
      cleanup = "none";
    };

    # Align taps config with nix-homebrew
    taps = builtins.attrNames config.nix-homebrew.taps;

    # `brew install`
    brews = [
      "act"
      "asdf"
      "assemblyai/assemblyai/assemblyai"
      "autoconf@2.69"
      "awscli"
      "cirruslabs/cli/tart"
      "cirruslabs/cli/sshpass"
      "cloudflared"
      "cmake"
      # "codex" # disabled after s1ngularity attack
      "croc"
      "derailed/k9s/k9s"
      "dive"
      "direnv"
      "docker-compose"
      "docutils"
      "entr"
      "expat"
      "fastlane"
      "flyctl"
      "fontforge"
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
      "mas"
      "mysql"
      "neilberkman/clippy/clippy"
      "neofetch"
      "okteto"
      "ollama"
      "pidgin"
      "portaudio"
      "profanity"
      "protobuf"
      "redis"
      "ruby"
      "saml2aws"
      "saulpw/vd/visidata"
      "schappim/ocr/ocr"
      "scrcpy"
      "sops"
      "stern"
      "swift-format"
      "swiftlint"
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
      "xcbeautify"
      "xcode-build-server"
    ];

    # `brew install --cask`
    casks = [
      "1password"
      "1password-cli"
      "adobe-creative-cloud"
      "android-platform-tools"
      "android-studio"
      "autodesk-fusion"
      "bambu-studio"
      "barrier"
      "bentobox"
      "blender"
      "blip"
      "chatgpt"
      "chromedriver"
      "claude"
      "crossover"
      "cryptomator"
      "daisydisk"
      "discord"
      "displaylink"
      "docker-desktop"
      "fantastical"
      "figma"
      "gitbutler"
      "google-chrome"
      "hidock"
      "httpie"
      "iterm2"
      "itermai"
      "jordanbaird-ice"
      "jump-desktop-connect"
      "mac-mouse-fix"
      "modern-csv"
      "monodraw"
      "mountain-duck"
      "msty"
      "notion"
      "obsidian"
      "orion"
      "parsec"
      "postico"
      "proxyman"
      "roon"
      "runjs"
      "sf-symbols"
      "silhouette-studio"
      "slack"
      "soundsource"
      "skip"
      "stats"
      "sublime-merge"
      "sublime-text"
      "tomatobar"
      "warp"
      "zed"
      "zoom"
    ];
  };
}
