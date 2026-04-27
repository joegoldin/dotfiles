{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  enabled = pkgs ? llm-agents;

  # Get claudeLib via agent-skills re-export
  claudeLib = inputs.agent-skills.lib.${pkgs.system}.claudeLib;

  # WakaTime plugin for Claude Code (uses system wakatime-cli)
  wakatimePlugin = pkgs.callPackage ./wakatime-plugin { };

  # Local skills defined in this repo
  localSkill =
    name:
    claudeLib.mkSkill {
      inherit name;
      description = "";
    } (builtins.readFile ./skills/${name}/SKILL.md);

  localPlugin = claudeLib.mkPlugin {
    name = "local";
    description = "Local skills from dotfiles";
    skills = [
      (localSkill "git-hunk")
    ];
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
in
{
  # Add extra packages alongside claude (which is installed by the module)
  home.packages = lib.mkIf enabled [
    notifySendWrapper
  ];

  programs.claude-nix = lib.mkIf enabled {
    enable = true;
    package = pkgs.llm-agents.claude-code;
    plugins = [
      wakatimePlugin
      localPlugin
    ];
    extraAccounts = [ "work" ];
  };
}
