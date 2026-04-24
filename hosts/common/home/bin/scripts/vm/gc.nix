{ pkgs, ... }:
{
  name = "gc";
  desc = "List or delete VMs whose TTL has expired";
  flags = [
    { name = "--dry-run"; desc = "Show what would be deleted, without deleting"; bool = true; }
    { name = "--yes"; desc = "Delete without per-VM confirmation"; bool = true; }
  ];
  runtimeInputs = [ pkgs.jq ];
  bash = ''
    shopt -s nullglob
    SPECS=/var/lib/vm-specs
    metas=("$SPECS"/*/meta.json)
    now_ts=$(date +%s)

    expired=()
    for meta in "''${metas[@]}"; do
      name=$(basename "$(dirname "$meta")")
      touched=$(jq -r .last_touched "$meta")
      ttl_days=$(jq -r .ttl_days "$meta")
      touched_ts=$(date -d "$touched" +%s 2>/dev/null || echo 0)
      age_days=$(( (now_ts - touched_ts) / 86400 ))
      if (( age_days > ttl_days )); then
        expired+=("$name:$age_days:$ttl_days")
      fi
    done

    if (( ''${#expired[@]} == 0 )); then
      green "nothing expired"
      exit 0
    fi

    yellow "expired VMs:"
    for e in "''${expired[@]}"; do
      IFS=: read -r name age ttl <<<"$e"
      printf '  %-22s  age=%s days  ttl=%s days\n' "$name" "$age" "$ttl"
    done

    [ -n "$dry_run" ] && exit 0

    for e in "''${expired[@]}"; do
      IFS=: read -r name _ _ <<<"$e"
      if [ -n "$yes" ]; then
        vm rm --force "$name"
      else
        vm rm "$name"
      fi
    done
  '';
}
