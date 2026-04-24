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
    state_dir="/var/lib/microvms/$name"
    spec_dir="/var/lib/vm-specs/$name"

    if [ ! -d "$state_dir" ] && [ ! -d "$spec_dir" ]; then
      die "no such VM: $name"
    fi

    if [ -z "$force" ]; then
      read -r -p "delete VM '$name' and all its state? [y/N] " reply
      [[ "$reply" =~ ^[yY] ]] || { yellow "cancelled"; exit 0; }
    fi

    # Stop the service whether it's running, activating, or failed.
    if systemctl is-active --quiet "microvm@$name" 2>/dev/null \
      || systemctl is-failed --quiet "microvm@$name" 2>/dev/null; then
      blue "stopping"
      [ -n "$force" ] && systemctl kill --signal=KILL "microvm@$name" 2>/dev/null || true
      systemctl stop "microvm@$name" 2>/dev/null || true
      systemctl reset-failed "microvm@$name" 2>/dev/null || true
    fi

    if [ -n "$keep_disk" ]; then
      archive="$HOME/vm-archives"
      mkdir -p "$archive"
      ts=$(date +%Y%m%d-%H%M%S)
      src="$state_dir/root.img"
      if [ -f "$src" ]; then
        blue "archiving disk → $archive/$name-$ts.img"
        cp "$src" "$archive/$name-$ts.img"
      fi
    fi

    blue "cleaning up"
    # vmusers has write on the parent dirs, so rmdir/unlink don't need sudo.
    rm -rf "$state_dir" "$spec_dir"
    # gcroots dir is root-owned; needs sudo.
    sudo rm -f "/nix/var/nix/gcroots/microvm/$name" "/nix/var/nix/gcroots/microvm/booted-$name" 2>/dev/null || true

    # Remove DHCP lease (file is vmusers-writable)
    lease_file=/var/lib/microvms/dnsmasq.leases
    if grep -q ",$name," "$lease_file" 2>/dev/null; then
      tmp=$(mktemp)
      grep -v ",$name," "$lease_file" > "$tmp" || true
      cp "$tmp" "$lease_file"
      rm -f "$tmp"
      systemctl reload-or-restart dnsmasq
    fi

    green "deleted $name"
  '';
}
