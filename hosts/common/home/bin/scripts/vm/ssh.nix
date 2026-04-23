{ pkgs, ... }:
{
  name = "ssh";
  desc = "SSH into a VM as joe (uses CLI-managed key)";
  params = [
    { name = "NAME"; desc = "VM name"; }
  ];
  runtimeInputs = with pkgs; [
    openssh
    jq
  ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm ssh <name> [command...]"
    shift || true
    meta="/var/lib/vm-specs/$name/meta.json"
    [ -f "$meta" ] || die "no such VM: $name"

    ip=$(jq -r .ip "$meta")
    user=$(jq -r .user "$meta")
    [ -n "$ip" ] || die "no IP stored in meta.json"

    key=/var/lib/microvms/ssh/id_ed25519
    [ -r "$key" ] || die "CLI ssh key not readable ($key). Re-login to pick up vmusers group?"

    exec ssh \
      -i "$key" \
      -o StrictHostKeyChecking=accept-new \
      -o UserKnownHostsFile=/dev/null \
      -o LogLevel=ERROR \
      "$user@$ip" "$@"
  '';
}
