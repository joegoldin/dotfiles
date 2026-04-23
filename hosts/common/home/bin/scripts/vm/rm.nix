{ pkgs, ... }:
{
  name = "rm";
  desc = "Delete a VM (stops it first if running)";
  params = [ { name = "NAME"; desc = "VM name"; } ];
  flags = [
    { name = "--force"; desc = "Skip confirmation; force-kill if running"; bool = true; }
    { name = "--keep-disk"; desc = "Move root disk to ~/vm-archives/ before deleting"; bool = true; }
  ];
  runtimeInputs = with pkgs; [
    jq
    systemd
  ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm rm <name>"
    meta="/var/lib/microvms/$name/meta.json"
    [ -f "$meta" ] || die "no such VM: $name"

    if [ -z "$force" ]; then
      read -r -p "delete VM '$name' and all its state? [y/N] " reply
      [[ "$reply" =~ ^[yY] ]] || { yellow "cancelled"; exit 0; }
    fi

    if systemctl is-active --quiet "microvm@$name"; then
      blue "stopping"
      if [ -n "$force" ]; then
        systemctl kill --signal=KILL "microvm@$name" || true
        systemctl stop "microvm@$name" || true
      else
        systemctl stop "microvm@$name"
      fi
    fi

    if [ -n "$keep_disk" ]; then
      archive="$HOME/vm-archives"
      mkdir -p "$archive"
      ts=$(date +%Y%m%d-%H%M%S)
      src="/var/lib/microvms/$name/disks/root.img"
      if [ -f "$src" ]; then
        blue "archiving disk → $archive/$name-$ts.img"
        sudo cp "$src" "$archive/$name-$ts.img"
        sudo chown "$USER:users" "$archive/$name-$ts.img"
      fi
    fi

    blue "unregistering"
    sudo microvm -R "$name" 2>/dev/null || true
    sudo rm -rf "/var/lib/microvms/$name"

    # Remove DHCP lease
    lease_file=/var/lib/microvms/dnsmasq.leases
    if grep -q ",$name," "$lease_file" 2>/dev/null; then
      tmp=$(mktemp)
      grep -v ",$name," "$lease_file" > "$tmp" || true
      sudo cp "$tmp" "$lease_file"
      rm -f "$tmp"
      sudo systemctl reload-or-restart dnsmasq
    fi

    green "deleted $name"
  '';
}
