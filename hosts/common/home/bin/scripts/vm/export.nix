{ pkgs, ... }:
{
  name = "export";
  desc = "Bundle a VM (meta + disks) to stdout or a file";
  params = [ { name = "NAME"; desc = "VM name"; } ];
  flags = [
    { name = "--output"; short = "-o"; arg = "FILE"; desc = "Write to FILE (default: stdout)"; }
    { name = "--no-disk"; desc = "Metadata only (rebuild disk from profile on import)"; bool = true; }
  ];
  runtimeInputs = with pkgs; [
    gnutar
    zstd
    jq
    systemd
  ];
  bash = ''
    name="''${1:-}"
    [ -z "$name" ] && die "usage: vm export <name> [-o file.tar.zst]"
    spec="/var/lib/vm-specs/$name"
    state="/var/lib/microvms/$name"
    [ -d "$spec" ] || die "no such VM: $name"

    if systemctl is-active --quiet "microvm@$name"; then
      die "'$name' is running — stop it first (vm stop $name)"
    fi

    # Bundle spec dir (meta.json, module.nix, flake.nix) and optionally disks.
    # Stage into a temp dir so tar sees both roots at once.
    staging=$(mktemp -d)
    trap 'rm -rf "$staging"' EXIT
    cp -r "$spec"/. "$staging/"
    if [ -z "$no_disk" ]; then
      if compgen -G "$state/*.img" >/dev/null 2>&1; then
        mkdir -p "$staging/disks"
        # Disk images are microvm-owned; user in kvm group can read.
        cp "$state"/*.img "$staging/disks/" 2>/dev/null || true
      fi
    fi

    if [ -n "$output" ]; then
      tar -C "$staging" -cf - . | zstd -T0 -19 -o "$output"
      green "exported → $output"
    else
      tar -C "$staging" -cf - . | zstd -T0 -19
    fi
  '';
}
