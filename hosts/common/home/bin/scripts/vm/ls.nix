{ pkgs, ... }:
{
  name = "ls";
  desc = "List all VMs (name, profile, state, IP, TTL remaining)";
  examples = [
    { cmd = "vm ls"; desc = "Show all VMs in a table"; }
  ];
  runtimeInputs = with pkgs; [
    jq
    systemd
    glibc
  ];
  bash = ''
    SPECS=/var/lib/vm-specs
    shopt -s nullglob

    printf '%-22s %-12s %-10s %-15s %-6s\n' NAME PROFILE STATE IP TTL-DAYS
    printf '%-22s %-12s %-10s %-15s %-6s\n' ---- ------- ----- -- --------

    dirs=("$SPECS"/*/meta.json)
    if (( ''${#dirs[@]} == 0 )); then
      echo "(no VMs — try 'vm new <name>')"
      exit 0
    fi

    for meta in "''${dirs[@]}"; do
      dir=$(dirname "$meta")
      name=$(basename "$dir")
      profile=$(jq -r .profile "$meta" 2>/dev/null || echo "?")
      paused=$(jq -r .paused "$meta" 2>/dev/null || echo "false")
      state=$(systemctl is-active "microvm@$name" 2>/dev/null || echo "inactive")
      [ "$paused" = "true" ] && state="paused"
      ip=$(getent hosts "$name.vm" 2>/dev/null | awk '{print $1}')
      [ -z "$ip" ] && ip="—"

      # TTL remaining
      ttl_days=$(jq -r .ttl_days "$meta" 2>/dev/null || echo "—")
      touched=$(jq -r .last_touched "$meta" 2>/dev/null || echo "")
      if [ -n "$touched" ] && [ "$ttl_days" != "—" ]; then
        touched_ts=$(date -d "$touched" +%s 2>/dev/null || echo 0)
        now_ts=$(date +%s)
        elapsed=$(( (now_ts - touched_ts) / 86400 ))
        remaining=$(( ttl_days - elapsed ))
        ttl_display="$remaining"
      else
        ttl_display="—"
      fi

      printf '%-22s %-12s %-10s %-15s %-6s\n' "$name" "$profile" "$state" "$ip" "$ttl_display"
    done
  '';
}
