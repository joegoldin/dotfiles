{ inputs, ... }:
let
  ghostty = inputs.ghostty;
in
{
  den.aspects.ghostty.homeManager =
    {
      pkgs,
      lib,
      ...
    }:
    let
      ghosttySettings = import ./_settings.nix { inherit lib; };
    in
    {
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
