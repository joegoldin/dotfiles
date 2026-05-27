{
  pkgs,
  lib,
  ...
}:
let
  enabled = pkgs ? llm-agents;
in
{
  programs.claude-nix = lib.mkIf enabled {
    enable = true;
    package = pkgs.llm-agents.claude-code;
    extraAccounts = [ "work" ];
    settings.skillListingBudgetFraction = 0.04;
  };
}
