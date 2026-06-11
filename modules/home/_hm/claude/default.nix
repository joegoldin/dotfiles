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
  programs.claude-nix = lib.mkIf enabled {
    enable = true;
    package = pkgs.llm-agents.claude-code;
    settings.skillListingBudgetFraction = 0.04;

    # Punch host-side paths Claude needs to push/pull over SSH through
    # the default sandbox deny list. 1Password's SSH agent socket
    # covers the agent-backed signing flow; known_hosts and ~/.ssh/config
    # cover host-key verification and per-host config. Private key files
    # (id_*) are deliberately omitted — using the 1Password agent is the
    # supported path here.
    extraSandbox.filesystem.read.allowWithinDeny = [
      "${homeDir}/.1password/agent.sock"
      "${homeDir}/.ssh/known_hosts"
      "${homeDir}/.ssh/known_hosts2"
      "${homeDir}/.ssh/config"
    ];
  };
}
