{ pkgs, ... }:
{
  name = "umount";
  desc = "Remove a host directory share from a VM (requires restart)";
  params = [
    { name = "NAME"; desc = "VM name"; }
    { name = "PATH"; desc = "Destination path (e.g. /mnt/foo) or source path"; }
  ];
  flags = [
    { name = "--now"; desc = "Restart the VM immediately"; bool = true; }
  ];
  runtimeInputs = with pkgs; [
    jq
    systemd
  ];
  bash = ''
    name="''${1:-}"
    path="''${2:-}"
    [ -z "$name" ] || [ -z "$path" ] && die "usage: vm umount <name> <path-or-src>"
    meta="/var/lib/vm-specs/$name/meta.json"
    [ -f "$meta" ] || die "no such VM: $name"

    tmp=$(mktemp)
    jq --arg p "$path" '.mounts |= map(select(.dst != $p and .src != $p))' "$meta" > "$tmp"
    cp "$tmp" "$meta"
    rm -f "$tmp"

    blue "regenerating module"
    staged=$(mktemp -d)
    cp "$meta" "$staged/meta.json"
    user_pub="$HOME/.ssh/id_ed25519.pub"
    user_flag=()
    [ -f "$user_pub" ] && user_flag=(--user-pub "$user_pub")
    vm-module-gen \
      --meta "$staged/meta.json" --out "$staged" \
      --profiles-dir /var/lib/vm-specs/profiles \
      --repo-root "''${VM_DOTFILES:-$HOME/dotfiles}" \
      --cli-pub /var/lib/microvms/ssh/id_ed25519.pub "''${user_flag[@]}"
    cp "$staged/module.nix" "$staged/flake.nix" "/var/lib/vm-specs/$name/"
    rm -rf "$staged"

    sudo microvm -u "$name"
    sudo chown -R root:vmusers "/var/lib/vm-specs/$name"
    sudo chmod -R g+rw "/var/lib/vm-specs/$name"

    if systemctl is-active --quiet "microvm@$name"; then
      if [ -n "$now" ]; then
        vm restart "$name"
      else
        yellow "removed — restart with: vm restart $name"
      fi
    fi

    green "unmounted $path"
  '';
}
