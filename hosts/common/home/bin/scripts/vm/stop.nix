{ pkgs, ... }:
{
  name = "stop";
  desc = "Stop a running VM (graceful shutdown)";
  params = [ { name = "NAME"; desc = "VM name"; } ];
  flags = [
    { name = "--timeout"; arg = "SECS"; desc = "Grace period before SIGKILL"; default = "20"; }
  ];
  runtimeInputs = with pkgs; [
    jq
    systemd
  ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm stop <name>"
    meta="/var/lib/microvms/$name/meta.json"
    [ -f "$meta" ] || die "no such VM: $name"

    if ! systemctl is-active --quiet "microvm@$name"; then
      yellow "$name is not running"
      exit 0
    fi

    blue "stopping $name (grace $timeout s)"
    # systemctl stop blocks until the unit is inactive; TimeoutStopSec handles the kill
    if ! timeout "$timeout" systemctl stop "microvm@$name"; then
      red "graceful stop timed out, forcing kill"
      systemctl kill --signal=KILL "microvm@$name" || true
    fi

    now=$(date -Iseconds)
    tmp=$(mktemp)
    jq --arg t "$now" '.last_touched = $t | .paused = false' "$meta" > "$tmp"
    sudo cp "$tmp" "$meta"
    rm -f "$tmp"

    green "stopped"
  '';
}
