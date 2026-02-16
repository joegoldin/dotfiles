{
  pkgs,
  lib,
  ...
}: let
  ghosttySettings = import ../common/home/ghostty-settings.nix {inherit lib;};
in {
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = false;
    settings = ghosttySettings.baseSettings;
  };
}
