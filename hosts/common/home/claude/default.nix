{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  enabled = pkgs ? llm-agents;
  wakatimePlugin = inputs.agent-skills.packages.${pkgs.system}.wakatimePlugin;
in
{
  programs.claude-nix = lib.mkIf enabled {
    enable = true;
    package = pkgs.llm-agents.claude-code;
    plugins = [ wakatimePlugin ];
    extraAccounts = [ "work" ];
  };
}
