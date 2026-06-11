{
  pkgs,
  lib,
  ...
}:
let
  enabled = pkgs ? llm-agents;
in
{
  programs.codex-nix = lib.mkIf enabled {
    enable = true;
    package = pkgs.llm-agents.codex;
    settings = {
      approval_policy = "on-request";
      sandbox_mode = "workspace-write";
    };
  };
}
