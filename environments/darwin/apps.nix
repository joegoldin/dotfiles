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

  environment.variables.EDITOR = "zed";

  # Mac App Store apps configuration
  # Homebrew packages and configuration are managed in homebrew.nix
  homebrew = {
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
      Peek = 1554235898;
      Patterns = 429449079;
      RocketSim = 1504940162;
      DevCleaner = 1388020431;
      ACompanionForSwiftUI = 1485436674;
      AppleDeveloper = 640199958;
      DavinciResolve = 571213070;
      Streamyfin = 6593660679;
    };
  };
}

