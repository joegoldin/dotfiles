_: {
  den.aspects.shell-tools.homeManager = {
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
    };
  };
}
