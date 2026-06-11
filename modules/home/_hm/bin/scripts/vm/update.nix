{ pkgs, ... }:
{
  name = "update";
  desc = "Refresh the flake lock and rebuild a VM's runner from latest dotfiles";
  params = [
    {
      name = "NAME";
      desc = "VM name (omit to update all VMs)";
      required = false;
    }
  ];
  flags = [
    { name = "--restart"; desc = "Restart running VMs after update"; bool = true; }
    { name = "--no-lock"; desc = "Skip flake lock update (rebuild with current pins)"; bool = true; }
  ];
  runtimeInputs = with pkgs; [
    nix
    systemd
  ];
  bash = ''
    update_one() {
      local name="$1"
      local spec="/var/lib/vm-specs/$name"
      [ -d "$spec" ] || die "no such VM: $name"

      # Regenerate module.nix / flake.nix from the current module-gen.py so
      # recent changes to common-guest / render_spice / etc. reach the runner.
      blue "regenerating module for $name"
      staged=$(mktemp -d)
      cp "$spec/meta.json" "$staged/meta.json"
      user_pub="$HOME/.ssh/id_ed25519.pub"
      user_flag=()
      [ -f "$user_pub" ] && user_flag=(--user-pub "$user_pub")
      vm-module-gen \
        --meta "$staged/meta.json" --out "$staged" \
        --profiles-dir /var/lib/vm-specs/profiles \
        --repo-root "''${VM_DOTFILES:-$HOME/dotfiles}" \
        --cli-pub /var/lib/microvms/ssh/id_ed25519.pub "''${user_flag[@]}"
      cp "$staged/module.nix" "$staged/flake.nix" "$spec/"
      rm -rf "$staged"

      if [ -z "$no_lock" ]; then
        blue "updating flake inputs for $name"
        # flake.lock is vmusers-writable after `vm new` sets perms.
        nix flake update --flake "$spec"
      fi

      blue "rebuilding runner for $name"
      sudo microvm -u "$name"
      # microvm -u may rewrite flake.lock as root; normalize perms.
      sudo chown -R root:vmusers "$spec"
      sudo chmod -R g+rw "$spec"

      if [ -n "$restart" ] && systemctl is-active --quiet "microvm@$name"; then
        blue "restarting $name"
        vm restart "$name"
      fi
      green "$name updated"
    }

    name="''${1:-}"
    if [ -n "$name" ]; then
      update_one "$name"
    else
      shopt -s nullglob
      any=0
      for spec in /var/lib/vm-specs/*/; do
        [ -f "$spec/meta.json" ] || continue
        any=1
        update_one "$(basename "$spec")"
      done
      [ "$any" = "1" ] || yellow "no VMs to update"
    fi
  '';
}
