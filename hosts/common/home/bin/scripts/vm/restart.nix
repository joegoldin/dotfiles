{ pkgs, ... }:
{
  name = "restart";
  desc = "Restart a VM (stop + start)";
  params = [ { name = "NAME"; desc = "VM name"; } ];
  runtimeInputs = with pkgs; [ systemd ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm restart <name>"
    [ -f "/var/lib/vm-specs/$name/meta.json" ] || die "no such VM: $name"
    vm stop "$name"
    vm start "$name"
  '';
}
