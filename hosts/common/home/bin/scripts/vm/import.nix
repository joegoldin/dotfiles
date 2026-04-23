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

    if [ -d "/var/lib/microvms/$target" ]; then
      die "VM '$target' already exists (remove first or pass a new name)"
    fi

    # Re-derive MAC from name if renamed
    if [ "$target" != "$orig" ]; then
      mac_hash=$(printf '%s' "$target" | sha1sum | awk '{print $1}')
      new_mac="02:''${mac_hash:0:2}:''${mac_hash:2:2}:''${mac_hash:4:2}:''${mac_hash:6:2}:''${mac_hash:8:2}"
      tmp=$(mktemp)
      jq --arg n "$target" --arg m "$new_mac" '.name=$n | .hostname=$n | .mac=$m' "$meta" > "$tmp"
      mv "$tmp" "$meta"
    fi

    # Install
    sudo mkdir -p "/var/lib/microvms/$target"
    sudo cp -r "$staging"/. "/var/lib/microvms/$target/"
    sudo chown -R microvm:vmusers "/var/lib/microvms/$target"
    sudo chmod -R g+rw "/var/lib/microvms/$target"
    rm -rf "$staging"

    # Regenerate module/flake (pub keys and repo root may differ from source host)
    staged=$(mktemp -d)
    sudo cp "/var/lib/microvms/$target/meta.json" "$staged/meta.json"
    sudo chown "$USER:users" "$staged/meta.json"
    user_pub="$HOME/.ssh/id_ed25519.pub"
    user_flag=()
    [ -f "$user_pub" ] && user_flag=(--user-pub "$user_pub")
    vm-module-gen \
      --meta "$staged/meta.json" --out "$staged" \
      --profiles-dir /var/lib/microvms/profiles \
      --repo-root "''${VM_DOTFILES:-$HOME/dotfiles}" \
      --cli-pub /var/lib/microvms/ssh/id_ed25519.pub "''${user_flag[@]}"
    sudo cp "$staged/module.nix" "$staged/flake.nix" "/var/lib/microvms/$target/"
    rm -rf "$staged"

    # Register with microvm.nix
    sudo microvm -c "$target" -f "git+file:///var/lib/microvms/$target#$target"

    # dnsmasq lease
    mac=$(jq -r .mac "/var/lib/microvms/$target/meta.json")
    mac_hash=$(printf '%s' "$target" | sha1sum | awk '{print $1}')
    ip_suffix=$(( 16#''${mac_hash:10:2} % 240 + 10 ))
    vm_ip="10.100.0.$ip_suffix"
    echo "$mac,$vm_ip,$target,12h" | sudo tee -a /var/lib/microvms/dnsmasq.leases >/dev/null
    sudo systemctl reload-or-restart dnsmasq

    green "imported $target (ip $vm_ip)"
  '';
}
