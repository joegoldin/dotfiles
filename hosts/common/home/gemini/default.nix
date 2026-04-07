{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  enabled = pkgs ? llm-agents;
in
{
  imports = [ "${inputs.gemini-nix}/modules/home-manager.nix" ];

  programs.gemini-nix = lib.mkIf enabled {
    enable = true;
    package = pkgs.llm-agents.gemini-cli;
    plugins = [ ];
    settings = {
      general.enableNotifications = true;
      skills.enabled = true;
    };
  };
}
