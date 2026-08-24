# Claude Code (claude-nix) + the agent-skills library.
{ inputs, ... }:
{
  den.aspects.claude.homeManager =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      enabled = pkgs ? llm-agents;
      homeDir = config.home.homeDirectory;
    in
    {
      imports = [
        inputs.agent-skills.homeManagerModules.claude
        inputs.agent-skills.homeManagerModules.agent-skills
      ];

      # Skill-owned tool packages (figr, pxd, vibecad, ...) ride into Claude's
      # own sandbox PATH via programs.claude-nix.plugins' --plugin-dir, which
      # never touches home.packages — so they're reachable from the agent's
      # Bash tool but invisible at an interactive prompt. re-shell is meant to
      # be run by a human at a terminal (it manages job control, Ctrl-C, TTY
      # state), so it needs to be on the login shell's PATH explicitly.
      home.packages = lib.mkIf enabled [
        inputs.agent-skills.packages.${pkgs.system}.re-shell
      ];

      programs.claude-nix = lib.mkIf enabled {
        enable = true;
        package = pkgs.llm-agents.claude-code;
        # This machine ships a lot of skills; 1% of the window truncates
        # their descriptions before the model ever sees the trigger text.
        skills.skillListingBudgetFraction = 0.04;

        # Punch host-side paths Claude needs to push/pull over SSH back
        # through the sandbox's read deny. 1Password's SSH agent socket
        # covers the agent-backed signing flow; known_hosts and ~/.ssh/config
        # cover host-key verification and per-host config. Private key files
        # (id_*) are deliberately omitted; using the 1Password agent is the
        # supported path here.
        extraSandbox.filesystem.allowRead = [
          "${homeDir}/.1password/agent.sock"
          "${homeDir}/.ssh/known_hosts"
          "${homeDir}/.ssh/known_hosts2"
          "${homeDir}/.ssh/config"
        ];
      };
    };
}
