{
  pkgs,
  lib,
  ...
}:
let
  enabled = (pkgs ? llm-agents) && (pkgs.llm-agents ? antigravity);
in
{
  programs.antigravity-cli-nix = lib.mkIf enabled {
    enable = true;
    package = pkgs.llm-agents.antigravity;
    settings = {
      general.enableNotifications = true;
      skills.enabled = true;
    };
  };
}
