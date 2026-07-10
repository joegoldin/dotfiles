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
          # First-class defaults. Note: codex-nix's activation merges
          # generated-over-existing, so these pin the model/effort and win over
          # interactive /model + /config edits on every switch.
          model = "gpt-5.6-sol";
          model_reasoning_effort = "xhigh";
        };
      };
    };
}
