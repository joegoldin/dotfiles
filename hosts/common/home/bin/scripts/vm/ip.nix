{ pkgs, ... }:
{
  name = "ip";
  desc = "Print the IP address of a VM";
  params = [ { name = "NAME"; desc = "VM name"; } ];
  runtimeInputs = [ pkgs.jq ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm ip <name>"
    meta="/var/lib/vm-specs/$name/meta.json"
    [ -f "$meta" ] || die "no such VM: $name"
    jq -r .ip "$meta"
  '';
}
