{
  name = "secret-helper";
  desc = "Manage agenix secrets (add/edit/remove/decrypt/rekey/list)";
  usage = "secret-helper <command> [name]";
  examples = [
    {
      cmd = "secret-helper add my_api_key";
      desc = "Create a new secret";
    }
    {
      cmd = "secret-helper rekey";
      desc = "Re-encrypt all secrets after key changes";
    }
  ];
  hostOnly = true;
  bash = ''
    set -euo pipefail

    # Standalone clone of github:joegoldin/dotfiles-secrets (no longer a
    # submodule); override with DOTFILES_SECRETS.
    SECRETS_DIR="''${DOTFILES_SECRETS:-$HOME/dotfiles-secrets}"

    # Source identity command from secrets repo.
    # identity.sh must define IDENTITY_CMD — a shell command that outputs the
    # private key to stdout. Example:
    #
    #   # 1Password:
    #   IDENTITY_CMD='op read "op://Vault/Key Name/private key?ssh-format=openssh"'
    #
    #   # File on disk:
    #   IDENTITY_CMD='cat ~/.ssh/id_ed25519'
    #
    if [ ! -f "$SECRETS_DIR/identity.sh" ]; then
      echo "Error: $SECRETS_DIR/identity.sh not found"
      echo "Clone it first: git clone git@github.com:joegoldin/dotfiles-secrets ~/dotfiles-secrets"
      echo "Create it with a line like: IDENTITY_CMD='cat ~/.ssh/id_ed25519'"
      exit 1
    fi
    source "$SECRETS_DIR/identity.sh"

    usage() {
      echo "Usage: secret-helper <command> <secret-name>"
      echo ""
      echo "Commands:"
      echo "  add    <name>   Create a new secret (adds to secrets.nix + encrypts)"
      echo "  edit   <name>   Edit an existing secret"
      echo "  remove <name>   Remove a secret (deletes .age file + removes from secrets.nix)"
      echo "  decrypt <name> <output>  Decrypt a secret to a file"
      echo "  rekey           Re-encrypt all secrets (after changing keys in secrets.nix)"
      echo "  list            List all secrets"
      echo ""
      echo "Examples:"
      echo "  $0 add my_api_key"
      echo "  $0 edit atuin_key"
      echo "  $0 remove old_secret"
      exit 1
    }

    ensure_age_name() {
      local name="$1"
      # Strip .age suffix if provided
      name="''${name%.age}"
      echo "''${name}.age"
    }

    identity_args() {
      local keyfile
      keyfile=$(mktemp)
      trap "rm -f '$keyfile'" EXIT
      eval "$IDENTITY_CMD" > "$keyfile"
      echo "$keyfile"
    }

    cmd_list() {
      echo "Secrets defined in secrets.nix:"
      grep '\.age' "$SECRETS_DIR/secrets.nix" | sed 's/.*"\(.*\.age\)".*/  \1/'
    }

    cmd_add() {
      local name
      name=$(ensure_age_name "$1")
      local bare="''${name%.age}"

      if grep -q "\"$name\"" "$SECRETS_DIR/secrets.nix"; then
        echo "$name already in secrets.nix, skipping"
      else
        # Add entry to secrets.nix (before closing brace, users-only by default)
        sed -i "s|^}$|  \"$name\".publicKeys = users;\n}|" "$SECRETS_DIR/secrets.nix"
        echo "Added $name to secrets.nix (publicKeys = users)"
      fi

      # Create the encrypted file
      local keyfile
      keyfile=$(mktemp)
      eval "$IDENTITY_CMD" > "$keyfile"
      cd "$SECRETS_DIR"
      EDITOR="''${EDITOR:-nano}" agenix -e "$name" -i "$keyfile"
      rm -f "$keyfile"

      echo "Created $name"
    }

    cmd_edit() {
      local name
      name=$(ensure_age_name "$1")

      if ! grep -q "\"$name\"" "$SECRETS_DIR/secrets.nix"; then
        echo "Error: $name not found in secrets.nix"
        exit 1
      fi

      local keyfile
      keyfile=$(mktemp)
      eval "$IDENTITY_CMD" > "$keyfile"
      cd "$SECRETS_DIR"
      EDITOR="''${EDITOR:-nano}" agenix -e "$name" -i "$keyfile"
      rm -f "$keyfile"

      echo "Updated $name"
    }

    cmd_remove() {
      local name
      name=$(ensure_age_name "$1")

      if [ ! -f "$SECRETS_DIR/$name" ]; then
        echo "Error: $name does not exist"
        exit 1
      fi

      read -rp "Remove $name? [y/N] " confirm
      if [[ "$confirm" != [yY] ]]; then
        echo "Cancelled"
        exit 0
      fi

      rm -f "$SECRETS_DIR/$name"
      sed -i "/\"$name\"/d" "$SECRETS_DIR/secrets.nix"

      echo "Removed $name"
    }

    cmd_decrypt() {
      local name output
      name=$(ensure_age_name "$1")
      output="$2"

      if [ ! -f "$SECRETS_DIR/$name" ]; then
        echo "Error: $name does not exist"
        exit 1
      fi

      local keyfile
      keyfile=$(mktemp)
      eval "$IDENTITY_CMD" > "$keyfile"
      cd "$SECRETS_DIR"
      agenix -d "$name" -i "$keyfile" > "$output"
      rm -f "$keyfile"

      echo "Decrypted $name -> $output"
    }

    cmd_rekey() {
      local keyfile
      keyfile=$(mktemp)
      eval "$IDENTITY_CMD" > "$keyfile"
      cd "$SECRETS_DIR"
      agenix --rekey -i "$keyfile"
      rm -f "$keyfile"

      echo "All secrets rekeyed"
    }

    [[ $# -lt 1 ]] && usage

    case "$1" in
      add)
        [[ $# -lt 2 ]] && usage
        cmd_add "$2"
        ;;
      edit)
        [[ $# -lt 2 ]] && usage
        cmd_edit "$2"
        ;;
      remove)
        [[ $# -lt 2 ]] && usage
        cmd_remove "$2"
        ;;
      decrypt)
        [[ $# -lt 3 ]] && usage
        cmd_decrypt "$2" "$3"
        ;;
      rekey)
        cmd_rekey
        ;;
      list)
        cmd_list
        ;;
      *)
        usage
        ;;
    esac
  '';
}
