{
  pkgs,
  lib,
  inputs,
  config,
  ...
}: let
  enabled = pkgs ? llm-agents;

  # Get the latest claude-code from llm-agents
  claude-code-latest = pkgs.llm-agents.claude-code;

  # Get claude-nix library with explicitly overridden claude-code
  claudeLib = import "${inputs.claude-nix}/lib" {
    pkgs = pkgs.extend (final: prev: {
      claude-code = claude-code-latest;
    });
  };

  # WSL-compatible notify-send wrapper (detects wsl-notify-send.exe at runtime)
  notifySendWrapper = pkgs.writeShellScriptBin "notify-send" ''
    # Wrapper that uses wsl-notify-send.exe on WSL
    if command -v wsl-notify-send.exe &> /dev/null; then
      # Convert notify-send args to wsl-notify-send format
      # notify-send [OPTIONS] SUMMARY [BODY] -> wsl-notify-send MESSAGE
      message=""
      for arg in "$@"; do
        case "$arg" in
          -*) ;; # Skip options
          *)
            if [ -z "$message" ]; then
              message="$arg"
            else
              message="$message: $arg"
            fi
            ;;
        esac
      done
      wsl-notify-send.exe --appId "Claude Code" -c "Claude Code" "''${message:-Notification}"
    else
      ${pkgs.libnotify}/bin/notify-send "$@"
    fi
  '';

  # Build code-notify package
  codeNotify = pkgs.callPackage ./code-notify.nix {};

  # Skills to extract from superpowers (upstream)
  skillNames = [
    "using-superpowers"
    "brainstorming"
    "receiving-code-review"
    "requesting-code-review"
    "subagent-driven-development"
    "systematic-debugging"
    "test-driven-development"
    "using-git-worktrees"
    "verification-before-completion"
    "writing-plans"
    "writing-skills"
  ];

  # Wrap an upstream skill
  wrapSkill = name:
    pkgs.runCommand "skill-${name}" {} ''
      mkdir -p $out/skills/${name}
      cp -r ${inputs.superpowers}/skills/${name}/* $out/skills/${name}/
    '';

  # Local skills (modified or custom)
  localSkill = name:
    pkgs.runCommand "skill-${name}" {} ''
      mkdir -p $out/skills/${name}
      cp -r ${./skills}/${name}/* $out/skills/${name}/
    '';

  # All skill derivations
  superpowersSkillDerivations =
    (map wrapSkill skillNames)
    ++ [
      (localSkill "claude-nix-config")
      (localSkill "executing-plans")
      (localSkill "gh-pr-review")
      (localSkill "obsidian-cli")
    ];

  # Custom commands
  prReviewCommand =
    claudeLib.mkCommand {
      name = "pr-review";
      description = "Fetch and analyze inline PR review comments for the current branch";
      allowed-tools = ["Bash" "Read" "Glob" "Grep" "Skill"];
    } ''
      Invoke the gh-pr-review skill, then fetch and analyze inline PR review comments for the current branch.

      IMPORTANT: ghreview is a fish function. Always run it via: fish -c 'ghreview ...'
      Include bot comments by default (Copilot, etc.) — do NOT pass --no-bots unless the user asks.

      Steps:
      1. Use the Skill tool to load the gh-pr-review skill
      2. Run `fish -c 'ghreview --raw'` to get the full review JSON (includes code context by default)
      3. Summarize each reviewer's feedback (including bots like Copilot)
      4. List all unresolved comments grouped by file, with the referenced code and the reviewer's concern
      5. Categorize feedback (bugs, security, performance, style, architecture, questions)
      6. Propose a prioritized plan to address the comments

      If there are thread replies, note which comments already have responses and which are unanswered.

      $ARGUMENTS
    '';

  # Copy hooks from superpowers (includes session-start hook)
  superpowersHooks = pkgs.runCommand "superpowers-hooks" {} ''
    mkdir -p $out/hooks
    cp -r ${inputs.superpowers}/hooks/* $out/hooks/
    chmod +x $out/hooks/*.sh 2>/dev/null || true
  '';

  # Create the superpowers plugin using claude-nix
  superpowersPlugin = claudeLib.mkPlugin {
    name = "superpowers";
    description = "Core skills library: TDD, debugging, collaboration patterns, and proven techniques (from github:obra/superpowers)";
    skills = superpowersSkillDerivations;
    commands = [
      prReviewCommand
    ];
  };

  # Attribution file for the plugin
  attributionFile = pkgs.writeTextFile {
    name = "superpowers-attribution";
    text = ''
      Skills in this plugin are sourced from:
      https://github.com/obra/superpowers

      Licensed under MIT License

      These skills are vendored and synced via:
      nix flake update superpowers
    '';
    destination = "/ATTRIBUTION";
  };

  # Complete plugin with hooks, attribution, and license
  superpowersPluginComplete = pkgs.buildEnv {
    name = "superpowers-complete";
    paths = [
      superpowersPlugin
      superpowersHooks
      attributionFile
      (pkgs.runCommand "superpowers-license" {} ''
        mkdir -p $out
        cp ${inputs.superpowers}/LICENSE $out/SUPERPOWERS-LICENSE
      '')
    ];
  };

  # Create wrapped claude binary with plugins using mkClaude (uses pkgsWithLatestClaude.claude-code)
  claudeWithPlugins = claudeLib.mkClaude {
    plugins = [
      superpowersPluginComplete
    ];
  };

  # Generate settings.json content
  settingsContent = import ./settings.nix {
    inherit lib codeNotify;
  };
in {
  # Add claude (with plugins) and code-notify to packages
  # notify-send wrapper handles WSL (wsl-notify-send.exe) vs native (libnotify)
  home.packages = lib.mkIf enabled [
    claudeWithPlugins
    codeNotify
    notifySendWrapper
  ];

  # Generate settings.json
  home.file.".claude/settings.json" = lib.mkIf enabled {
    text = builtins.toJSON settingsContent;
  };
}
