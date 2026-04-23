{ pkgs, ... }:
{
  name = "logs";
  desc = "Show systemd logs for a VM (journalctl -u microvm@<name>)";
  params = [ { name = "NAME"; desc = "VM name"; } ];
  flags = [
    { name = "--follow"; short = "-f"; desc = "Follow new entries"; bool = true; }
    { name = "--lines"; short = "-n"; arg = "N"; desc = "Show last N lines"; default = "100"; }
  ];
  runtimeInputs = [ pkgs.systemd ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm logs <name>"
    [ -f "/var/lib/vm-specs/$name/meta.json" ] || die "no such VM: $name"

    args=(-u "microvm@$name" -n "$lines")
    [ -n "$follow" ] && args+=(-f)
    exec journalctl "''${args[@]}"
  '';
}
