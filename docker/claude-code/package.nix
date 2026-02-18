{
  lib,
  writeShellScriptBin,
  stdenvNoCC,
  coreutils,
}:
let
  dockerContext = stdenvNoCC.mkDerivation {
    name = "claude-container-docker-context";
    src = lib.cleanSource ./.;
    dontPatchShebangs = true;
    installPhase = ''
      mkdir -p $out
      cp Dockerfile entrypoint.sh managed-settings.json $out/
    '';
  };
in
writeShellScriptBin "claude-container" ''
  set -euo pipefail

  IMAGE="claude-code"
  CONFIG_DIR="''${HOME}/.config/claude-container"
  CONTEXT_DIR="${dockerContext}"

  usage() {
    echo "Usage: claude-container <command> [options]"
    echo ""
    echo "Commands:"
    echo "  build              Build the Claude Code container image"
    echo "  run [workspace]    Run Claude Code (sandboxed, default: current dir)"
    echo "  yolo [workspace]   Run Claude Code (skip all permission prompts)"
    echo "  shell [workspace]  Drop into a bash shell in the container"
    echo ""
  }

  case "''${1:-}" in
    build)
      echo "🔨  Building Claude Code container..."
      docker build -t "$IMAGE" -f "$CONTEXT_DIR/Dockerfile" "$CONTEXT_DIR"
      echo "✅  Built!"
      ;;
    run)
      ws="''${2:-$(${coreutils}/bin/pwd)}"
      mkdir -p "$CONFIG_DIR"
      echo "🚀  Starting Claude Code container..."
      echo "    Workspace: $ws"
      echo "    Config:    $CONFIG_DIR"
      docker run --rm -it \
        -v "$ws:/workspace" \
        -v "$CONFIG_DIR:/claude" \
        -e "CLAUDE_CONFIG_DIR=/claude" \
        -e "USER_UID=$(id -u)" \
        -e "USER_GID=$(id -g)" \
        "$IMAGE"
      ;;
    yolo)
      ws="''${2:-$(${coreutils}/bin/pwd)}"
      mkdir -p "$CONFIG_DIR"
      echo "🚀  Starting Claude Code container (yolo mode)..."
      echo "    Workspace: $ws"
      echo "    Config:    $CONFIG_DIR"
      docker run --rm -it \
        -v "$ws:/workspace" \
        -v "$CONFIG_DIR:/claude" \
        -e "CLAUDE_CONFIG_DIR=/claude" \
        -e "USER_UID=$(id -u)" \
        -e "USER_GID=$(id -g)" \
        "$IMAGE" claude --dangerously-skip-permissions
      ;;
    shell)
      ws="''${2:-$(${coreutils}/bin/pwd)}"
      mkdir -p "$CONFIG_DIR"
      docker run --rm -it \
        -v "$ws:/workspace" \
        -v "$CONFIG_DIR:/claude" \
        -e "CLAUDE_CONFIG_DIR=/claude" \
        -e "USER_UID=$(id -u)" \
        -e "USER_GID=$(id -g)" \
        "$IMAGE" /bin/bash
      ;;
    *)
      usage
      exit 1
      ;;
  esac
''
