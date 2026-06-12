# Antigravity CLI (antigravity-cli-nix).
{ inputs, ... }:
{
  den.aspects.antigravity.homeManager =
    { pkgs, lib, ... }:
    {
      imports = [ inputs.agent-skills.homeManagerModules.antigravity ];

      programs.antigravity-cli-nix =
        lib.mkIf ((pkgs ? llm-agents) && (pkgs.llm-agents ? antigravity-cli))
          {
            enable = true;
            package = pkgs.llm-agents.antigravity-cli;
            settings = {
              general.enableNotifications = true;
              skills.enabled = true;
            };
          };
    };
}
