{ pkgs, ... }:
{
  name = "pause";
  desc = "Pause a running VM (freeze CPU, keep RAM)";
  params = [ { name = "NAME"; desc = "VM name"; } ];
  runtimeInputs = with pkgs; [
    jq
    socat
    systemd
  ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm pause <name>"
    meta="/var/lib/vm-specs/$name/meta.json"
    [ -f "$meta" ] || die "no such VM: $name"

    if ! systemctl is-active --quiet "microvm@$name"; then
      die "$name is not running"
    fi

    # microvm.nix puts the QMP socket at /var/lib/microvms/<name>/<name>.sock
    sock="/var/lib/microvms/$name/$name.sock"
    [ -S "$sock" ] || die "no QMP socket at $sock (VM may not be fully started)"

    # QMP handshake + stop. The socket is owned by the `microvm` user with no
    # group write, so socat needs sudo to actually connect.
    printf '%s\n%s\n' \
      '{"execute":"qmp_capabilities"}' \
      '{"execute":"stop"}' \
      | sudo socat - "UNIX-CONNECT:$sock" >/dev/null

    now=$(date -Iseconds)
    tmp=$(mktemp)
    jq --arg t "$now" '.last_touched = $t | .paused = true' "$meta" > "$tmp"
    sudo cp "$tmp" "$meta"
    rm -f "$tmp"

    green "paused"
  '';
}
