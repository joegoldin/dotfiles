{
  pkgs,
  ghostty,
  lib,
  ...
}:
let
  ghosttySettings = import ./ghostty-settings.nix { inherit lib; };
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
}
