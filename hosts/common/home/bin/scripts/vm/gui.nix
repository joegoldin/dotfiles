{ pkgs, ... }:
{
  name = "gui";
  desc = "Open a SPICE viewer for the VM's graphical display";
  params = [ { name = "NAME"; desc = "VM name"; } ];
  runtimeInputs = with pkgs; [
    jq
    systemd
    virt-viewer
  ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm gui <name>"
    meta="/var/lib/microvms/$name/meta.json"
    [ -f "$meta" ] || die "no such VM: $name"

    gui=$(jq -r .gui "$meta")
    if [ "$gui" != "true" ]; then
      die "'$name' was created without --gui (no SPICE graphics)"
    fi

    if ! systemctl is-active --quiet "microvm@$name"; then
      read -r -p "'$name' is not running. Start it? [Y/n] " reply
      if [[ ! "$reply" =~ ^[nN] ]]; then
        vm start "$name"
      else
        exit 1
      fi
    fi

    sock="/var/lib/microvms/$name/spice.sock"
    # Wait up to 10s for the SPICE socket to appear
    for _ in $(seq 1 20); do
      [ -S "$sock" ] && break
      sleep 0.5
    done
    [ -S "$sock" ] || die "SPICE socket never appeared at $sock"

    blue "opening viewer for $name"
    exec setsid remote-viewer "spice+unix://$sock" --title "vm: $name" >/dev/null 2>&1 &
  '';
}
