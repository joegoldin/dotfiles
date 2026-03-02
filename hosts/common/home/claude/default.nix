{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  enabled = pkgs ? llm-agents;

  # Get the latest claude-code from llm-agents
  claude-code-latest = pkgs.llm-agents.claude-code;

  # Get claude-nix library with explicitly overridden claude-code
  claudeLib = import "${inputs.claude-nix}/lib" {
    pkgs = pkgs.extend (
      final: prev: {
        claude-code = claude-code-latest;
      }
    );
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
  codeNotify = pkgs.callPackage ./code-notify.nix { };

  # Get the agent-skills plugin (includes all skills, commands, agents, hooks, MCP, LSP)
  agentSkillsPlugin = inputs.agent-skills.packages.${pkgs.system}.default;

  # Create wrapped claude binary with plugins
  claudeWithPluginsBase = claudeLib.mkClaude {
    plugins = [ agentSkillsPlugin ];
  };

  # Wrap claude to always pass --verbose
  claudeWithPlugins = pkgs.writeShellScriptBin "claude" ''
    exec ${claudeWithPluginsBase}/bin/claude --verbose "$@"
  '';

  # Generate settings.json content
  settingsContent = import ./settings.nix {
    inherit codeNotify;
  };
in
{
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
