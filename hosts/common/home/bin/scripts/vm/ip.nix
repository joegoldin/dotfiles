{ pkgs, ... }:
{
  name = "ip";
  desc = "Print the IP address of a VM";
  params = [ { name = "NAME"; desc = "VM name"; } ];
  runtimeInputs = [ pkgs.glibc ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm ip <name>"
    ip=$(getent hosts "$name.vm" | awk '{print $1}')
    [ -z "$ip" ] && die "no IP assigned to '$name' (is the VM running?)"
    echo "$ip"
  '';
}
