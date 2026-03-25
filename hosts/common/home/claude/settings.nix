{ codeNotify }:
{
  attribution = {
    commit = "";
    pr = "";
  };

  cleanupPeriodDays = 14;

  env = {
    DISABLE_AUTOUPDATER = "1";
    CLAUDE_CODE_DISABLE_AUTO_MEMORY = "1";
  };

  permissions = {
    allow = [
      # File operations
      "Bash(find:*)"
      "Bash(grep:*)"
      "Bash(ls:*)"
      # Git operations
      "Bash(git show:*)"
      "Bash(git rev-parse:*)"
      # Build tools
      "Bash(mkdir:*)"
      # Python
      "Bash(python -m py_compile:*)"
      "Bash(black:*)"
      "Bash(isort:*)"
      # Skills
      "Skill(using-superpowers)"
      "Skill(writing-plans)"
      "Skill(executing-plans)"
      "Skill(subagent-driven-development)"
      "Skill(update-config)"
      "Skill(keybindings-help)"
      "Skill(simplify)"
      "Skill(loop)"
      "Skill(claude-api)"
      "Skill(agent-skills:gh-pr-review)"
      "Skill(agent-skills:test-driven-development)"
      "Skill(agent-skills:nix-helper)"
      "Skill(agent-skills:requesting-code-review)"
      "Skill(agent-skills:receiving-code-review)"
      "Skill(agent-skills:using-git-worktrees)"
      "Skill(agent-skills:writing-skills)"
      "Skill(agent-skills:obsidian-cli)"
      "Skill(agent-skills:claude-nix-config)"
      "Skill(agent-skills:brainstorming)"
      "Skill(agent-skills:systematic-debugging)"
      "Skill(agent-skills:verification-before-completion)"
    ];
    deny = [
      "Read(./.env)"
      "Read(./.env.*)"
    ];
    defaultMode = "acceptEdits";
  };

  # SessionStart hook is handled by the superpowers plugin
  hooks = {
    Notification = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "${codeNotify}/lib/code-notify/core/notifier.sh notification";
          }
        ];
      }
    ];
    Stop = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "${codeNotify}/lib/code-notify/core/notifier.sh stop";
          }
        ];
      }
    ];
    PreToolUse = [
      {
        matcher = "Bash";
        hooks = [
          {
            type = "command";
            command = "${codeNotify}/lib/code-notify/core/notifier.sh PreToolUse";
          }
        ];
      }
    ];
  };

  enabledPlugins = { };

  alwaysThinkingEnabled = true;

  showTurnDuration = true;

  spinnerTipsEnabled = false;
}
