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
    dir="/var/lib/microvms/$name"
    [ -d "$dir" ] || die "no such VM: $name"

    if systemctl is-active --quiet "microvm@$name"; then
      die "'$name' is running — stop it first (vm stop $name)"
    fi

    # Build the set of paths to include
    paths=(meta.json module.nix flake.nix)
    [ -z "$no_disk" ] && [ -d "$dir/disks" ] && paths+=(disks)

    if [ -n "$output" ]; then
      sudo tar -C "$dir" -cf - "''${paths[@]}" | zstd -T0 -19 -o "$output"
      green "exported → $output"
    else
      sudo tar -C "$dir" -cf - "''${paths[@]}" | zstd -T0 -19
    fi
  '';
}
