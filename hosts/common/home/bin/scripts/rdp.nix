{
  name = "rdp";
  desc = "Connect to a remote desktop via RDP (disables secondary monitors)";
  usage = "rdp [user@]<hostname>";
  type = "bash";
  body = ''
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

    # Find enabled non-primary outputs
    secondary=$(ssh "$user@$host" "$kscreen -o" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | awk '
      /^Output:/ { if (name && enabled && !primary) print name; name=$3; enabled=0; primary=0 }
      /enabled/ { enabled=1 }
      /priority 1/ { primary=1 }
      END { if (name && enabled && !primary) print name }
    ') || true

    restore_monitors() {
      if [[ -n "$secondary" ]]; then
        echo "Re-enabling secondary monitors: $secondary"
        args=""
        for mon in $secondary; do
          args+=" output.$mon.enable"
        done
        ssh "$user@$host" "$kscreen $args" 2>/dev/null || true
      fi
    }

    trap restore_monitors EXIT

    # Disable secondary monitors
    if [[ -n "$secondary" ]]; then
      echo "Disabling secondary monitors: $secondary"
      args=""
      for mon in $secondary; do
        args+=" output.$mon.disable"
      done
      ssh "$user@$host" "$kscreen $args"
    fi

    # Connect
    xfreerdp /v:"$host" /u:"$user" /d: /smart-sizing || true
  '';
}
