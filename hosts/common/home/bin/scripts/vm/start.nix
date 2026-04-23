{ pkgs, ... }:
{
  name = "start";
  desc = "Start a VM (or resume it if paused)";
  params = [ { name = "NAME"; desc = "VM name"; } ];
  runtimeInputs = with pkgs; [
    jq
    systemd
    socat
  ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm start <name>"
    meta="/var/lib/microvms/$name/meta.json"
    [ -f "$meta" ] || die "no such VM: $name"

    paused=$(jq -r .paused "$meta")
    if [ "$paused" = "true" ]; then
      blue "$name is paused → resuming"
      exec vm resume "$name"
    fi

    if systemctl is-active --quiet "microvm@$name"; then
      yellow "$name is already running"
      exit 0
    fi

    blue "starting $name"
    systemctl start "microvm@$name"

    # Touch last_touched
    now=$(date -Iseconds)
    tmp=$(mktemp)
    jq --arg t "$now" '.last_touched = $t' "$meta" > "$tmp"
    sudo cp "$tmp" "$meta"
    rm -f "$tmp"

    green "started"
  '';
}
