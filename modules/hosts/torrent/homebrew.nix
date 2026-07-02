{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  username = meta.username;
in
{
  den.aspects.torrent.darwin =
    {
      config,
      pkgs,
      ...
    }:
    {
      # ---------------------------------------------------------------------------
      # Homebrew: GUI casks + Mac App Store apps only.
      #
      # CLI tools are managed by nixpkgs via home-manager (./packages and
      # modules/home/_hm/packages); `mas` (which backs `homebrew.masApps` in
      # apps.nix) is installed system-side below.
      #
      # macOS 27 note: this Homebrew (5.1.x) predates macOS 27, so any bottle
      # (formula) install/upgrade raises `unknown or unsupported macOS version:
      # :dunno`. Casks don't use bottles, so cask installs are unaffected. With
      # `upgrade`/`autoUpdate` off and `mas` already installed, activation never
      # touches a bottle.
      # ---------------------------------------------------------------------------
      nix-homebrew = {
        enable = true;

        # Apple Silicon: also expose the Intel prefix for Rosetta 2.
        enableRosetta = true;

        user = username;

        autoMigrate = true;

        taps = {
          "homebrew/homebrew-core" = inputs.homebrew-core;
          "homebrew/homebrew-cask" = inputs.homebrew-cask;
          "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
        };

        # Fully-declarative taps: no imperative `brew tap`.
        mutableTaps = false;
      };

      homebrew = {
        enable = true;

        onActivation = {
          # Never fetch/upgrade bottles; see the macOS 27 note above.
          autoUpdate = false;
          upgrade = false;
          cleanup = "none";
        };

        taps = builtins.attrNames config.nix-homebrew.taps;

        # No formulae at all; CLI tools come from nixpkgs. `brew bundle` finds
        # the nix-installed `mas` (below) on PATH.
        brews = [ ];

        # `brew install --cask`
        casks = [
          "1password"
          "1password-cli"
          "affinity"
          "android-platform-tools"
          "android-studio"
          "autodesk-fusion"
          "bambu-studio"
          "barrier"
          "bentobox"
          "blender"
          "chatgpt"
          "claude"
          "crossover"
          "cryptomator"
          "daisydisk"
          "discord"
          "displaylink"
          "fantastical"
          "figma"
          "ghostty"
          "gitbutler"
          "google-chrome"
          "hidock"
          "iterm2"
          "itermai"
          "jump-desktop-connect"
          "mac-mouse-fix"
          "modern-csv"
          "monodraw"
          "mountain-duck"
          "msty"
          "notion"
          "obsidian"
          "orbstack"
          "parsec"
          "postico"
          "proxyman"
          "rocket"
          "roon"
          "runjs"
          "sf-symbols"
          # "silhouette-studio"
          "slack"
          "soundsource"
          "stats"
          "sublime-merge"
          "sublime-text"
          "tomatobar"
          "typora"
          "zed"
          "zoom"
        ];
      };

      # `mas` backs `homebrew.masApps` at system activation, so it must be
      # system-wide rather than in home.packages.
      environment.systemPackages = [ pkgs.mas ];
    };
}
