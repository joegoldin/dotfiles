{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:

let
  # Get claude-nix library for current system
  system = pkgs.stdenv.hostPlatform.system;
  claudeLib = inputs.claude-nix.lib.${system};

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
  codeNotify = pkgs.callPackage ./code-notify.nix { };

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
  wrapSkill = name: pkgs.runCommand "skill-${name}" { } ''
    mkdir -p $out/skills/${name}
    cp -r ${inputs.superpowers}/skills/${name}/* $out/skills/${name}/
  '';

  # Local skills (modified or custom)
  localSkill = name: pkgs.runCommand "skill-${name}" { } ''
    mkdir -p $out/skills/${name}
    cp -r ${./skills}/${name}/* $out/skills/${name}/
  '';

  # All skill derivations
  superpowersSkillDerivations = (map wrapSkill skillNames) ++ [
    (localSkill "executing-plans")
  ];

  # Copy hooks from superpowers (includes session-start hook)
  superpowersHooks = pkgs.runCommand "superpowers-hooks" { } ''
    mkdir -p $out/hooks
    cp -r ${inputs.superpowers}/hooks/* $out/hooks/
    chmod +x $out/hooks/*.sh 2>/dev/null || true
  '';

  # Create the superpowers plugin using claude-nix
  superpowersPlugin = claudeLib.mkPlugin {
    name = "superpowers";
    description = "Core skills library: TDD, debugging, collaboration patterns, and proven techniques (from github:obra/superpowers)";
    skills = superpowersSkillDerivations;
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
      (pkgs.runCommand "superpowers-license" { } ''
        mkdir -p $out
        cp ${inputs.superpowers}/LICENSE $out/SUPERPOWERS-LICENSE
      '')
    ];
  };

  # Create wrapped claude binary with plugins using mkClaude
  claudeWithPlugins = claudeLib.mkClaude {
    plugins = [
      superpowersPluginComplete
    ];
  };

  # Generate settings.json content
  settingsContent = import ./settings.nix {
    inherit lib codeNotify;
  };

in
{
  # Add claude (with plugins) and code-notify to packages
  # notify-send wrapper handles WSL (wsl-notify-send.exe) vs native (libnotify)
  home.packages = [
    claudeWithPlugins
    codeNotify
    notifySendWrapper
  ];

  # Generate settings.json
  home.file.".claude/settings.json".text = builtins.toJSON settingsContent;
}
