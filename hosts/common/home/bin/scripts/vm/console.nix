{ pkgs, ... }:
{
  name = "console";
  desc = "Attach to the VM's serial console (exit with Ctrl-] q)";
  params = [ { name = "NAME"; desc = "VM name"; } ];
  runtimeInputs = [ pkgs.socat ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm console <name>"
    [ -f "/var/lib/vm-specs/$name/meta.json" ] || die "no such VM: $name"

    sock=$(find "/var/lib/microvms/$name" -name 'console*.sock' -type s 2>/dev/null | head -n1)
    [ -z "$sock" ] && die "no console socket found (VM not running?)"

    yellow "attached — Ctrl-] then q to detach"
    exec socat -,raw,echo=0,escape=0x1d "UNIX-CONNECT:$sock"
  '';
}
