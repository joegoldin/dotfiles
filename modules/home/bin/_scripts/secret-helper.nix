{ pkgs }:
{
  name = "secret-helper";
  desc = "Manage agenix secrets, and age-encrypt any file with the same identity";
  usage = "secret-helper <command> [args]";
  examples = [
    {
      cmd = "secret-helper add my_api_key";
      desc = "Create a new secret";
    }
    {
      cmd = "secret-helper rekey";
      desc = "Re-encrypt all secrets after key changes";
    }
    {
      cmd = "secret-helper encrypt-file .env";
      desc = "Encrypt any file on disk to .env.age";
    }
    {
      cmd = "secret-helper decrypt-file .env.age .env";
      desc = "Decrypt any .age file back";
    }
  ];
  hostOnly = true;
  # age does the arbitrary-file work; agenix only knows about $SECRETS_DIR.
  # openssh gives us ssh-keygen -y to turn the identity into a recipient.
  runtimeInputs = [
    pkgs.age
    pkgs.openssh
  ];
  # The identity is a real private key on disk for the duration of the command,
  # so remove it on every exit path rather than only on success.
  beforeExit = ''
    rm -f "''${IDENTITY_KEYFILE:-}" "''${RECIPIENT_FILE:-}" 2>/dev/null || true
  '';
  bash = ''
    set -euo pipefail

    # Standalone clone of github:joegoldin/dotfiles-secrets (no longer a
    # submodule); override with DOTFILES_SECRETS.
    SECRETS_DIR="''${DOTFILES_SECRETS:-$HOME/dotfiles-secrets}"

    # Source identity command from secrets repo.
    # identity.sh must define IDENTITY_CMD; a shell command that outputs the
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
      echo "Usage: secret-helper <command> [args]"
      echo ""
      echo "Managed secrets (live in \$SECRETS_DIR, tracked in secrets.nix):"
      echo "  add    <name>   Create a new secret (adds to secrets.nix + encrypts)"
      echo "  edit   <name>   Edit an existing secret"
      echo "  remove <name>   Remove a secret (deletes .age file + removes from secrets.nix)"
      echo "  decrypt <name> <output>  Decrypt a secret to a file"
      echo "  rekey           Re-encrypt all secrets (after changing keys in secrets.nix)"
      echo "  list            List all secrets"
      echo ""
      echo "Loose files (anywhere on disk, not tracked in secrets.nix):"
      echo "  encrypt-file <in> [out]   Encrypt any file (default out: <in>.age)"
      echo "  decrypt-file <in> [out]   Decrypt any .age file (default out: stdout)"
      echo "  dotenv <in> [fish]        Print a KEY=VALUE .age as shell assignments"
      echo "  recipient                 Print the age recipient for your identity"
      echo ""
      echo "Both groups authenticate with the same identity from"
      echo "\$SECRETS_DIR/identity.sh, so a 1Password-backed key works for both."
      echo ""
      echo "Examples:"
      echo "  $0 add my_api_key"
      echo "  $0 edit atuin_key"
      echo "  $0 remove old_secret"
      echo "  $0 encrypt-file ~/work/repo/scripts/.env"
      echo "  $0 decrypt-file ~/work/repo/scripts/.env.age ~/work/repo/scripts/.env"
      echo "  eval \"\$($0 dotenv creds.age)\"      # load into bash/zsh"
      echo "  secret-env creds.age                 # load into fish, no eval"
      exit 1
    }

    ensure_age_name() {
      local name="$1"
      # Strip .age suffix if provided
      name="''${name%.age}"
      echo "''${name}.age"
    }

    # Materialise the private key to a 0600 temp file and record the path so the
    # exit trap can remove it even if age/agenix fails partway.
    #
    # These set globals rather than echoing the path: a caller writing
    # `f=$(mk_identity_file)` would run the body in a subshell, the parent's
    # global would stay empty, and the trap would clean up nothing — leaving the
    # private key in /tmp for the rest of the boot.
    mk_identity_file() {
      IDENTITY_KEYFILE=$(mktemp)
      chmod 600 "$IDENTITY_KEYFILE"
      eval "$IDENTITY_CMD" > "$IDENTITY_KEYFILE"
    }

    # age accepts an SSH public key as a recipient, so the identity is the only
    # thing needed to encrypt as well as decrypt — no separate recipient list,
    # and anything encrypted this way opens on any machine that can reach the
    # same 1Password item.
    mk_recipient_file() {
      RECIPIENT_FILE=$(mktemp)
      ssh-keygen -y -f "$IDENTITY_KEYFILE" > "$RECIPIENT_FILE"
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

    # --- Loose files -------------------------------------------------------
    # agenix resolves paths against the secrets.nix in its working directory,
    # so it cannot touch a file sitting in some unrelated repo. These call age
    # directly with the same identity, which keeps one auth path (1Password)
    # for both kinds of secret.

    cmd_encrypt_file() {
      local input="$1"
      local output="''${2:-$1.age}"

      [ -f "$input" ] || { echo "Error: $input does not exist"; exit 1; }
      if [ -e "$output" ]; then
        read -rp "$output exists. Overwrite? [y/N] " confirm
        [[ "$confirm" == [yY] ]] || { echo "Cancelled"; exit 0; }
      fi

      mk_identity_file
      mk_recipient_file
      age -R "$RECIPIENT_FILE" -o "$output" "$input"

      echo "Encrypted $input -> $output"
      echo "The plaintext is untouched; remove it yourself if you meant to replace it."
    }

    cmd_decrypt_file() {
      local input="$1"
      local output="''${2:-}"

      [ -f "$input" ] || { echo "Error: $input does not exist"; exit 1; }

      mk_identity_file

      if [ -n "$output" ]; then
        if [ -e "$output" ]; then
          read -rp "$output exists. Overwrite? [y/N] " confirm
          [[ "$confirm" == [yY] ]] || { echo "Cancelled"; exit 0; }
        fi
        # Create at 0600 before age writes, so the plaintext is never briefly
        # world-readable.
        ( umask 077; : > "$output" )
        age -d -i "$IDENTITY_KEYFILE" -o "$output" "$input"
        echo "Decrypted $input -> $output"
      else
        age -d -i "$IDENTITY_KEYFILE" "$input"
      fi
    }

    cmd_recipient() {
      mk_identity_file
      ssh-keygen -y -f "$IDENTITY_KEYFILE"
    }

    # Decrypt a KEY=VALUE file and print it as shell assignments, for eval.
    #
    # A subcommand cannot export into the calling shell — a child process cannot
    # touch its parent's environment — so the caller still wraps this in eval.
    # What does move in here is everything that was fiddly: skipping comments and
    # blanks, ignoring junk lines, stripping quotes the file already had,
    # re-quoting values so spaces and $ survive, and emitting fish syntax, which
    # has no `export VAR=value` at all. Use the secret-env fish function to skip
    # the eval entirely.
    cmd_dotenv() {
      local input="$1"
      local style="''${2:-posix}"

      [ -f "$input" ] || { echo "Error: $input does not exist" >&2; exit 1; }

      mk_identity_file

      age -d -i "$IDENTITY_KEYFILE" "$input" | while IFS= read -r line || [ -n "$line" ]; do
        # Trim CR (files that have been through Windows) and leading space.
        line="''${line%$'\r'}"
        line="''${line#"''${line%%[![:space:]]*}"}"

        case "$line" in
          "" | "#"*) continue ;;
        esac

        # Tolerate a leading `export ` so an already-sourceable file works.
        case "$line" in
          "export "*) line="''${line#export }" ;;
        esac

        case "$line" in
          *=*) ;;
          *) continue ;;
        esac

        local key value
        key="''${line%%=*}"
        value="''${line#*=}"

        # Only real shell identifiers, so a malformed file cannot inject code.
        case "$key" in
          [A-Za-z_]*) ;;
          *) continue ;;
        esac
        case "$key" in
          *[!A-Za-z0-9_]*) continue ;;
        esac

        # Drop one layer of quoting the file supplied; we re-quote below.
        case "$value" in
          "\""*"\"") value="''${value#\"}"; value="''${value%\"}" ;;
          "'"*"'") value="''${value#\'}"; value="''${value%\'}" ;;
        esac

        # Escape what both sh and fish treat specially inside double quotes.
        local escaped
        escaped=$(printf '%s' "$value" | sed 's/[\\"$`]/\\&/g')

        if [ "$style" = "fish" ]; then
          printf 'set -gx %s "%s"\n' "$key" "$escaped"
        else
          printf 'export %s="%s"\n' "$key" "$escaped"
        fi
      done
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
      encrypt-file)
        [[ $# -lt 2 ]] && usage
        cmd_encrypt_file "$2" "''${3:-}"
        ;;
      decrypt-file)
        [[ $# -lt 2 ]] && usage
        cmd_decrypt_file "$2" "''${3:-}"
        ;;
      dotenv)
        [[ $# -lt 2 ]] && usage
        cmd_dotenv "$2" "''${3:-posix}"
        ;;
      recipient)
        cmd_recipient
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
