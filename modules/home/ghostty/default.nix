{ inputs, ... }:
let
  ghostty = inputs.ghostty;
in
{
  den.aspects.ghostty.homeManager =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      ghosttySettings = import ./_settings.nix { inherit lib; };
    in
    {
      home.sessionVariables.TERMINAL = "${config.programs.ghostty.package}/bin/ghostty";

      programs.ghostty = {
        enable = true;
        package = ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;
        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = false;
        settings = ghosttySettings.baseSettings;
      };
    };
}
