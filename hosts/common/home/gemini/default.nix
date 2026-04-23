{
  pkgs,
  lib,
  ...
}:
let
  enabled = pkgs ? llm-agents;
in
{
  programs.gemini-nix = lib.mkIf enabled {
    enable = true;
    package = pkgs.llm-agents.gemini-cli;
    settings = {
      general.enableNotifications = true;
      skills.enabled = true;
    };
  };
}
