{ pkgs, ... }:
{
  name = "import";
  desc = "Restore a VM from an export bundle (stdin or file)";
  params = [
    { name = "FILE"; desc = "Bundle path (use - for stdin)"; }
    { name = "NEW_NAME"; desc = "Optional rename"; required = false; }
  ];
  runtimeInputs = with pkgs; [
    gnutar
    zstd
    jq
    openssh
  ];
  bash = ''
    file="''${1:-}"
    new_name="''${2:-}"
    [ -z "$file" ] && die "usage: vm import <file|-> [NEW_NAME]"

    staging=$(mktemp -d)
    if [ "$file" = "-" ]; then
      zstd -d | tar -C "$staging" -xf -
    else
      zstd -d -o "$staging/bundle.tar" "$file"
      tar -C "$staging" -xf "$staging/bundle.tar"
      rm "$staging/bundle.tar"
    fi

    meta="$staging/meta.json"
    [ -f "$meta" ] || die "bundle missing meta.json"

    orig=$(jq -r .name "$meta")
    target=''${new_name:-$orig}

    if [ -d "/var/lib/vm-specs/$target" ] || [ -d "/var/lib/microvms/$target" ]; then
      die "VM '$target' already exists"
    fi

    # Re-derive MAC from (possibly new) name
    mac_hash=$(printf '%s' "$target" | sha1sum | awk '{print $1}')
    new_mac="02:''${mac_hash:0:2}:''${mac_hash:2:2}:''${mac_hash:4:2}:''${mac_hash:6:2}:''${mac_hash:8:2}"
    tmp=$(mktemp)
    jq --arg n "$target" --arg m "$new_mac" '.name=$n | .hostname=$n | .mac=$m' "$meta" > "$tmp"
    mv "$tmp" "$meta"

    # Regenerate module/flake in staging (pubkeys/repo may differ from source host)
    user_pub="$HOME/.ssh/id_ed25519.pub"
    user_flag=()
    [ -f "$user_pub" ] && user_flag=(--user-pub "$user_pub")
    vm-module-gen \
      --meta "$meta" --out "$staging" \
      --profiles-dir /var/lib/vm-specs/profiles \
      --repo-root "''${VM_DOTFILES:-$HOME/dotfiles}" \
      --cli-pub /var/lib/microvms/ssh/id_ed25519.pub "''${user_flag[@]}"

    # Cross-host disk restore is not supported in v1 — drop any bundled disks.
    if [ -d "$staging/disks" ]; then
      yellow "note: disk restore across hosts not yet supported — disks dropped"
      rm -rf "$staging/disks"
    fi

    # Move into vm-specs (CLI-owned)
    spec_dir="/var/lib/vm-specs/$target"
    sudo mv "$staging" "$spec_dir"
    sudo chown -R root:vmusers "$spec_dir"
    sudo chmod -R g+rw "$spec_dir"

    # Register with microvm.nix (creates /var/lib/microvms/$target/)
    sudo microvm -c "$target" -f "path:$spec_dir"

    # dnsmasq lease
    ip_suffix=$(( 16#''${mac_hash:10:2} % 240 + 10 ))
    vm_ip="10.100.0.$ip_suffix"
    echo "$new_mac,$vm_ip,$target,12h" | sudo tee -a /var/lib/microvms/dnsmasq.leases >/dev/null
    sudo systemctl reload-or-restart dnsmasq

    green "imported $target (ip $vm_ip)"
  '';
}
