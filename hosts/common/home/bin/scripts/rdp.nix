{
  name = "rdp";
  desc = "Connect to a remote desktop via RDP (disables secondary monitors)";
  hostOnly = true;
  params = [{ name = "HOST"; desc = "[user@]hostname to connect to"; }];
  examples = [
    { cmd = "rdp 192.168.1.10"; desc = "Connect as current user"; }
    { cmd = "rdp admin@office-pc"; desc = "Connect as admin"; }
  ];
  bash = ''
    if [[ $# -lt 1 ]]; then
      echo "Usage: rdp [user@]<hostname>"
      exit 1
    fi

    # Parse user@host or just host
    if [[ "$1" == *@* ]]; then
      user="''${1%%@*}"
      host="''${1#*@}"
    else
      user="$USER"
      host="$1"
    fi

    kscreen="WAYLAND_DISPLAY=wayland-0 QT_QPA_PLATFORM=wayland kscreen-doctor"

    # Get local screen resolution
    local_res=$(xdpyinfo 2>/dev/null | awk '/dimensions:/ { print $2; exit }') || true
    if [[ -z "''${local_res:-}" ]]; then
      local_res="2560x1440"
    fi
    local_w=''${local_res%x*}
    local_h=''${local_res#*x}

    green "Connecting to $host as $user (local: ''${local_w}x''${local_h})"

    # Parse remote outputs
    raw=$(ssh "$user@$host" "$kscreen -o" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g') || true

    primary_name=$(echo "$raw" | awk '/^Output:/ { name=$3; primary=0 } /priority 1/ { primary=1; print name }') || true
    primary_mode=$(echo "''${raw:-}" | awk -v out="''${primary_name:-}" '
      /^Output:/ { name=$3 }
      name == out && /Modes:/ {
        for (i=1; i<=NF; i++) {
          if ($i ~ /\*/) { gsub(/\*/, "", $i); split($i, a, ":"); print a[2]; exit }
        }
      }
    ') || true

    secondary=$(echo "''${raw:-}" | awk '
      /^Output:/ { if (name && enabled && !primary) print name; name=$3; enabled=0; primary=0 }
      /enabled/ { enabled=1 }
      /priority 1/ { primary=1 }
      END { if (name && enabled && !primary) print name }
    ') || true

    restore() {
      echo ""
      if [[ -n "$secondary" ]]; then
        blue "Re-enabling secondary monitors: $secondary"
        args=""
        for mon in $secondary; do
          args+=" output.$mon.enable"
        done
        ssh "$user@$host" "$kscreen $args" 2>/dev/null || true
      fi
      if [[ -n "$primary_name" && -n "$primary_mode" ]]; then
        blue "Restoring $primary_name to $primary_mode"
        ssh "$user@$host" "$kscreen output.$primary_name.mode.$primary_mode" 2>/dev/null || true
      fi
      green "Disconnected."
    }

    trap restore EXIT

    # Disable secondary monitors
    if [[ -n "$secondary" ]]; then
      blue "Disabling secondary monitors: $secondary"
      args=""
      for mon in $secondary; do
        args+=" output.$mon.disable"
      done
      ssh "$user@$host" "$kscreen $args" >/dev/null 2>&1 || true
    fi

    # Set remote resolution to match local (may fail if mode unavailable, xfreerdp handles it)
    if [[ -n "$primary_name" ]]; then
      blue "Setting $primary_name to ''${local_w}x''${local_h}"
      ssh "$user@$host" "$kscreen output.$primary_name.mode.''${local_w}x''${local_h}" >/dev/null 2>&1 || true
    fi

    green "Launching RDP session..."
    xfreerdp /v:"$host" /u:"$user" /d: /f /smart-sizing /monitors:0 /w:"$local_w" /h:"$local_h" /log-level:ERROR 2>/dev/null || true
  '';
}
