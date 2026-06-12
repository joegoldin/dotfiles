# Codex CLI (codex-nix).
{ inputs, ... }:
{
  den.aspects.codex.homeManager =
    { pkgs, lib, ... }:
    {
      imports = [ inputs.agent-skills.homeManagerModules.codex ];

      programs.codex-nix = lib.mkIf (pkgs ? llm-agents) {
        enable = true;
        package = pkgs.llm-agents.codex;
        settings = {
          approval_policy = "on-request";
          sandbox_mode = "workspace-write";
        };
      };
    };
}
