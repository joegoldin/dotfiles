{codeNotify}: {
  attribution = {
    commit = "";
    pr = "";
  };

  cleanupPeriodDays = 14;

  env = {
    DISABLE_AUTOUPDATER = "1";
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

  enabledPlugins = {};

  alwaysThinkingEnabled = true;

  showTurnDuration = true;

  spinnerTipsEnabled = false;
}
