{ pkgs, ... }:
{
  name = "touch";
  desc = "Reset a VM's TTL clock (extends its life in `vm gc`)";
  params = [ { name = "NAME"; desc = "VM name"; } ];
  runtimeInputs = [ pkgs.jq ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm touch <name>"
    meta="/var/lib/microvms/$name/meta.json"
    [ -f "$meta" ] || die "no such VM: $name"
    now=$(date -Iseconds)
    tmp=$(mktemp)
    jq --arg t "$now" '.last_touched = $t' "$meta" > "$tmp"
    sudo cp "$tmp" "$meta"
    rm -f "$tmp"
    green "$name touched ($now)"
  '';
}
