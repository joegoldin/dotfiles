{
  pkgs,
  ghostty,
  lib,
  ...
}:
let
  ghosttySettings = import ../common/home/ghostty-settings.nix { inherit lib; };
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
