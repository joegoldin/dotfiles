{ ... }:
{
  den.aspects.torrent.darwin = _: {
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
        Infuse = 1136220934;
        # Dongled (6465788521) is deliberately absent: it is an iPhone/iPad-only
        # app (minimum iOS 17.0, no Mac in its supportedDevices), so the Mac App
        # Store never serves it and `mas info 6465788521` cannot even resolve the
        # id — brew bundle failed the whole activation on it. Entries here need
        # either kind = mac-software or a Mac among supportedDevices; check with
        # `curl -s "https://itunes.apple.com/lookup?id=<id>&country=us"` before
        # adding one. Install Dongled on the iPad from the App Store instead.
      };
    };
  };
}
