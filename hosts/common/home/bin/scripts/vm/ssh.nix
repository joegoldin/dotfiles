{ pkgs, ... }:
{
  name = "ssh";
  desc = "SSH into a VM as joe (uses CLI-managed key)";
  params = [
    { name = "NAME"; desc = "VM name"; }
  ];
  runtimeInputs = with pkgs; [
    openssh
    glibc
  ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm ssh <name> [command...]"
    shift || true
    [ -f "/var/lib/microvms/$name/meta.json" ] || die "no such VM: $name"

    key=/var/lib/microvms/ssh/id_ed25519
    [ -r "$key" ] || die "CLI ssh key not readable ($key). Re-login to pick up vmusers group?"

    exec ssh \
      -i "$key" \
      -o StrictHostKeyChecking=accept-new \
      -o UserKnownHostsFile=/dev/null \
      -o LogLevel=ERROR \
      "joe@$name.vm" "$@"
  '';
}
