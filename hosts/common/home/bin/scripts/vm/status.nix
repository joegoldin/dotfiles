{ pkgs, ... }:
{
  name = "status";
  desc = "Show detailed status for a VM";
  params = [ { name = "NAME"; desc = "VM name"; } ];
  runtimeInputs = with pkgs; [
    jq
    systemd
    glibc
  ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm status <name>"
    meta="/var/lib/vm-specs/$name/meta.json"
    [ -f "$meta" ] || die "no such VM: $name"

    profile=$(jq -r .profile "$meta")
    ram=$(jq -r .ram_mb "$meta")
    cpu=$(jq -r .cpu "$meta")
    disk=$(jq -r .disk_gb "$meta")
    mac=$(jq -r .mac "$meta")
    gui=$(jq -r .gui "$meta")
    paused=$(jq -r .paused "$meta")
    created=$(jq -r .created_at "$meta")
    touched=$(jq -r .last_touched "$meta")
    ttl_days=$(jq -r .ttl_days "$meta")

    state=$(systemctl is-active "microvm@$name" 2>/dev/null || echo "inactive")
    [ "$paused" = "true" ] && state="paused"
    ip=$(getent hosts "$name.vm" | awk '{print $1}')
    [ -z "$ip" ] && ip="(not assigned)"

    bold "VM: $name"
    printf '  %-14s %s\n' "profile" "$profile"
    printf '  %-14s %s\n' "state" "$state"
    printf '  %-14s %s\n' "ip" "$ip"
    printf '  %-14s %s\n' "mac" "$mac"
    printf '  %-14s %s MB\n' "ram" "$ram"
    printf '  %-14s %s\n' "cpu" "$cpu"
    printf '  %-14s %s GB\n' "disk" "$disk"
    printf '  %-14s %s\n' "gui" "$gui"
    printf '  %-14s %s\n' "created" "$created"
    printf '  %-14s %s\n' "last touched" "$touched"
    printf '  %-14s %s\n' "ttl" "$ttl_days days"

    # Mounts
    mounts=$(jq -r '.mounts | length' "$meta")
    if [ "$mounts" -gt 0 ]; then
      echo ""
      bold "Mounts"
      jq -r '.mounts[] | "  \(.src) -> \(.dst)\(if .ro then " (ro)" else "" end)"' "$meta"
    fi

    # Extra packages
    pkgs_count=$(jq -r '.extra_pkgs | length' "$meta")
    if [ "$pkgs_count" -gt 0 ]; then
      echo ""
      bold "Extra packages"
      jq -r '.extra_pkgs[] | "  \(.)"' "$meta"
    fi
  '';
}
