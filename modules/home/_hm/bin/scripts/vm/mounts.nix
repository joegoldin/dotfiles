{ pkgs, ... }:
{
  name = "mounts";
  desc = "List mounts configured for a VM";
  params = [ { name = "NAME"; desc = "VM name"; } ];
  runtimeInputs = [ pkgs.jq ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm mounts <name>"
    meta="/var/lib/vm-specs/$name/meta.json"
    [ -f "$meta" ] || die "no such VM: $name"
    count=$(jq -r '.mounts | length' "$meta")
    if [ "$count" -eq 0 ]; then
      yellow "(no mounts)"
      exit 0
    fi
    jq -r '.mounts[] | "\(.src) → \(.dst)\(if .ro then " (ro)" else "" end)"' "$meta"
  '';
}
