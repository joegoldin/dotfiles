{ pkgs, ... }:
{
  name = "resume";
  desc = "Resume a paused VM";
  params = [ { name = "NAME"; desc = "VM name"; } ];
  runtimeInputs = with pkgs; [
    jq
    socat
    systemd
  ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm resume <name>"
    meta="/var/lib/vm-specs/$name/meta.json"
    [ -f "$meta" ] || die "no such VM: $name"

    paused=$(jq -r .paused "$meta")
    if [ "$paused" != "true" ]; then
      yellow "$name is not paused"
      exit 0
    fi

    sock=$(find "/var/lib/microvms/$name" -name 'qmp*.sock' -type s 2>/dev/null | head -n1)
    [ -z "$sock" ] && die "no QMP socket found"

    printf '%s\n%s\n' \
      '{"execute":"qmp_capabilities"}' \
      '{"execute":"cont"}' \
      | socat - "UNIX-CONNECT:$sock" >/dev/null

    now=$(date -Iseconds)
    tmp=$(mktemp)
    jq --arg t "$now" '.last_touched = $t | .paused = false' "$meta" > "$tmp"
    sudo cp "$tmp" "$meta"
    rm -f "$tmp"

    green "resumed"
  '';
}
