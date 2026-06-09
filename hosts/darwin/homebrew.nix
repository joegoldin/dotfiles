{
  inputs,
  config,
  username,
  ...
}:
{
  # ---------------------------------------------------------------------------
  # Thin Homebrew remnant — Mac App Store apps only.
  #
  # Homebrew is otherwise removed: CLI tools come from nixpkgs and GUI apps from
  # brew-nix (`pkgs.brewCasks.*`), both in ./system-packages.nix. The only left
  # that Nix can't do natively is declarative Mac App Store installs, which
  # nix-darwin drives through `mas` via `brew bundle` (masApps live in apps.nix).
  #
  # macOS 27 note: this Homebrew (5.1.x) predates macOS 27, so any bottle
  # install/upgrade raises `unknown or unsupported macOS version: :dunno`. The
  # remnant avoids that entirely by never fetching a bottle — `mas` is already
  # installed and `upgrade`/`autoUpdate` are off, so activation only runs
  # `mas install`, which doesn't touch bottles.
  # ---------------------------------------------------------------------------
  nix-homebrew = {
    enable = true;

    # Apple Silicon: also expose the Intel prefix for Rosetta 2.
    enableRosetta = true;

    user = username;

    autoMigrate = true;

    # Only the taps needed to resolve the `mas` formula.
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
    };

    # Fully-declarative taps: no imperative `brew tap`.
    mutableTaps = false;
  };

  homebrew = {
    enable = true;

    onActivation = {
      # Never fetch/upgrade bottles — see the macOS 27 note above.
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };

    taps = builtins.attrNames config.nix-homebrew.taps;

    # `mas` is the only formula kept — it backs `homebrew.masApps` (apps.nix).
    brews = [ "mas" ];
  };
}
