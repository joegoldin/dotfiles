{ pkgs, ... }:
let
  # WSL-compatible notify-send wrapper.
  # On WSL, delegate to wsl-notify-send.exe so notifications surface in
  # Windows. Elsewhere, fall back to libnotify's notify-send.
  notifySendWrapper = pkgs.writeShellScriptBin "notify-send" ''
    if command -v wsl-notify-send.exe &> /dev/null; then
      message=""
      for arg in "$@"; do
        case "$arg" in
          -*) ;;
          *)
            if [ -z "$message" ]; then
              message="$arg"
            else
              message="$message: $arg"
            fi
            ;;
        esac
      done
      wsl-notify-send.exe --appId "Notification" -c "Notification" "''${message:-Notification}"
    else
      ${pkgs.libnotify}/bin/notify-send "$@"
    fi
  '';
in
{
  home.packages = [ notifySendWrapper ];
}
