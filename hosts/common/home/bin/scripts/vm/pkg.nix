{ pkgs, ... }:
{
  name = "pkg";
  desc = "Manage extra packages on a VM (verbs: add, rm, ls)";
  usage = "vm pkg <add|rm|ls> <NAME> [pkg...]";
  runtimeInputs = with pkgs; [
    jq
    systemd
  ];
  bash = ''
    verb="''${1:-}"
    name="''${2:-}"
    shift 2 || true
    [ -z "$verb" ] || [ -z "$name" ] && die "usage: vm pkg <add|rm|ls> <NAME> [pkg...]"
    meta="/var/lib/vm-specs/$name/meta.json"
    [ -f "$meta" ] || die "no such VM: $name"

    regen() {
      staged=$(mktemp -d)
      sudo cp "$meta" "$staged/meta.json"
      sudo chown "$USER:users" "$staged/meta.json"
      user_pub="$HOME/.ssh/id_ed25519.pub"
      user_flag=()
      [ -f "$user_pub" ] && user_flag=(--user-pub "$user_pub")
      vm-module-gen \
        --meta "$staged/meta.json" --out "$staged" \
        --profiles-dir /var/lib/vm-specs/profiles \
        --repo-root "''${VM_DOTFILES:-$HOME/dotfiles}" \
        --cli-pub /var/lib/microvms/ssh/id_ed25519.pub "''${user_flag[@]}"
      sudo cp "$staged/module.nix" "$staged/flake.nix" "/var/lib/vm-specs/$name/"
      rm -rf "$staged"
      sudo microvm -u "$name"
    }

    case "$verb" in
      ls)
        jq -r '.extra_pkgs[]' "$meta" 2>/dev/null || true
        ;;
      add)
        [ "$#" -eq 0 ] && die "pkg add needs at least one package"
        tmp=$(mktemp)
        jq --argjson new "$(printf '%s\n' "$@" | jq -R . | jq -s .)" \
          '.extra_pkgs = (.extra_pkgs + $new | unique)' "$meta" > "$tmp"
        sudo cp "$tmp" "$meta"; rm -f "$tmp"
        blue "regenerating module"
        regen
        systemctl is-active --quiet "microvm@$name" && yellow "added — restart with: vm restart $name"
        green "added: $*"
        ;;
      rm)
        [ "$#" -eq 0 ] && die "pkg rm needs at least one package"
        tmp=$(mktemp)
        jq --argjson rem "$(printf '%s\n' "$@" | jq -R . | jq -s .)" \
          '.extra_pkgs |= map(select(. as $p | $rem | index($p) | not))' "$meta" > "$tmp"
        sudo cp "$tmp" "$meta"; rm -f "$tmp"
        blue "regenerating module"
        regen
        systemctl is-active --quiet "microvm@$name" && yellow "removed — restart with: vm restart $name"
        green "removed: $*"
        ;;
      *)
        die "unknown verb: $verb (use add, rm, or ls)"
        ;;
    esac
  '';
}
