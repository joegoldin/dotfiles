# Antigravity CLI (antigravity-cli-nix).
{ inputs, ... }:
{
  den.aspects.antigravity.homeManager =
    { customPackages, lib, ... }:
    {
      imports = [ inputs.agent-skills.homeManagerModules.antigravity ];

      programs.antigravity-cli-nix =
        lib.mkIf ((customPackages ? llm-agents) && (customPackages.llm-agents ? antigravity-cli))
          {
            enable = true;
            package = customPackages.llm-agents.antigravity-cli;
            # Antigravity's settings.json uses flat keys (per the CLI reference):
            # `notifications` is the real key. The old nested
            # `general.enableNotifications` / `skills.enabled` are not in the
            # schema (skills load automatically from plugins), so they were
            # no-ops.
            settings = {
              notifications = true;
            };
          };
    };
}
