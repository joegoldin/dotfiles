{ pkgs, ... }:
{
  name = "profile";
  desc = "Manage VM profiles (verbs: ls, show, edit, rm)";
  usage = "vm profile <ls|show|edit|rm> [NAME]";
  runtimeInputs = [ pkgs.jq ];
  bash = ''
    verb="''${1:-ls}"
    name="''${2:-}"

    case "$verb" in
      ls)
        bold "Built-in profiles:"
        for f in /var/lib/microvms/profiles/*.json; do
          [ -f "$f" ] || continue
          base=$(basename "$f" .json)
          desc=$(jq -r .description "$f" 2>/dev/null || echo "?")
          printf '  %-12s %s\n' "$base" "$desc"
        done
        if compgen -G "/var/lib/microvms/profiles/custom/*.json" >/dev/null; then
          echo ""
          bold "Custom profiles:"
          for f in /var/lib/microvms/profiles/custom/*.json; do
            base=$(basename "$f" .json)
            desc=$(jq -r .description "$f" 2>/dev/null || echo "?")
            printf '  %-12s %s\n' "$base" "$desc"
          done
        fi
        ;;
      show)
        [ -z "$name" ] && die "usage: vm profile show <name>"
        for f in "/var/lib/microvms/profiles/$name.json" "/var/lib/microvms/profiles/custom/$name.json"; do
          if [ -f "$f" ]; then
            jq . "$f"
            exit 0
          fi
        done
        die "no such profile: $name"
        ;;
      edit)
        [ -z "$name" ] && die "usage: vm profile edit <name>"
        custom="/var/lib/microvms/profiles/custom/$name.json"
        builtin="/var/lib/microvms/profiles/$name.json"
        if [ -f "$builtin" ]; then
          die "cannot edit built-in '$name' — use 'vm profile rm' first if you want to shadow it"
        fi
        if [ ! -f "$custom" ]; then
          die "no such custom profile: $name (create with: vm profile add $name)"
        fi
        "''${EDITOR:-vi}" "$custom"
        ;;
      add)
        [ -z "$name" ] && die "usage: vm profile add <name>"
        custom="/var/lib/microvms/profiles/custom/$name.json"
        builtin="/var/lib/microvms/profiles/$name.json"
        [ -f "$builtin" ] && die "'$name' is a built-in name"
        [ -f "$custom" ] && die "custom profile '$name' already exists"
        # Seed from minimal as a starting point
        sudo cp /var/lib/microvms/profiles/minimal.json "$custom"
        sudo chown "$USER:vmusers" "$custom"
        sudo chmod 0664 "$custom"
        tmp=$(mktemp)
        jq --arg n "$name" '.name = $n | .description = "Custom profile: " + $n' "$custom" > "$tmp"
        cp "$tmp" "$custom"
        rm -f "$tmp"
        "''${EDITOR:-vi}" "$custom"
        green "created $custom"
        ;;
      rm)
        [ -z "$name" ] && die "usage: vm profile rm <name>"
        custom="/var/lib/microvms/profiles/custom/$name.json"
        builtin="/var/lib/microvms/profiles/$name.json"
        [ -f "$builtin" ] && die "cannot remove built-in '$name'"
        [ -f "$custom" ] || die "no such custom profile: $name"
        sudo rm "$custom"
        green "removed $name"
        ;;
      *)
        die "unknown verb: $verb (use ls, show, add, edit, rm)"
        ;;
    esac
  '';
}
