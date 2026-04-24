{ pkgs, ... }:
{
  name = "mount";
  desc = "Add a host directory share to a VM (requires restart)";
  params = [
    { name = "NAME"; desc = "VM name"; }
    { name = "SPEC"; desc = "SRC[:DST][:ro] or . for current dir"; }
  ];
  flags = [
    { name = "--now"; desc = "Restart the VM immediately"; bool = true; }
    { name = "--defer"; desc = "Don't prompt; apply next restart"; bool = true; }
  ];
  runtimeInputs = with pkgs; [
    jq
    systemd
  ];
  bash = ''
    name="''${1:-}"
    spec="''${2:-}"
    [ -z "$name" ] || [ -z "$spec" ] && die "usage: vm mount <name> <SRC[:DST][:ro]|.>"
    meta="/var/lib/vm-specs/$name/meta.json"
    [ -f "$meta" ] || die "no such VM: $name"

    if [ "$spec" = "." ]; then
      src=$(pwd); dst=/mnt/cwd; ro=false
    else
      # Split on : — last segment may be ro/rw
      IFS=: read -ra parts <<<"$spec"
      last=''${parts[-1]}
      ro=false
      if [ "$last" = "ro" ] || [ "$last" = "rw" ]; then
        [ "$last" = "ro" ] && ro=true
        unset 'parts[-1]'
      fi
      src=''${parts[0]}
      src=$(realpath "$src")
      if [ "''${#parts[@]}" -gt 1 ]; then
        dst=''${parts[1]}
      else
        dst=/mnt/$(basename "$src")
      fi
    fi
    tag=$(echo "$dst" | sed 's|^/||;s|/|-|g;s|[^a-z0-9-]|-|g' | cut -c1-30)

    tmp=$(mktemp)
    jq --arg src "$src" --arg dst "$dst" --arg tag "$tag" --argjson ro "$ro" \
      '.mounts += [{"src":$src,"dst":$dst,"tag":$tag,"ro":$ro}]' "$meta" > "$tmp"
    cp "$tmp" "$meta"
    rm -f "$tmp"

    blue "regenerating module"
    user_pub="$HOME/.ssh/id_ed25519.pub"
    user_flag=()
    [ -f "$user_pub" ] && user_flag=(--user-pub "$user_pub")

    staged=$(mktemp -d)
    cp "$meta" "$staged/meta.json"
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
      elif [ -n "$defer" ]; then
        yellow "applied — restart with: vm restart $name"
      else
        read -r -p "restart $name now to apply? [y/N] " reply
        [[ "$reply" =~ ^[yY] ]] && vm restart "$name" || yellow "deferred — restart with: vm restart $name"
      fi
    fi

    green "mounted $src → $dst ($([ "$ro" = true ] && echo ro || echo rw))"
  '';
}
