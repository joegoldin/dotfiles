[private]
default: system-info
    @just --list

system-info:
    @echo "🖥️  This is an {{ arch() }} machine on {{ os() }}"

# ── Core commands ────────────────────────────────────────────────────────

[unix]
check: lint
    @echo "🔍  Checking Nix config for {{ arch() }}-{{ os() }}..."
    @NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix --extra-experimental-features 'nix-command flakes' flake check --impure --system {{ arch() }}-{{ os() }} --show-trace
    @echo "✅  Check completed!"

[unix]
lint:
    @echo "📝  Linting Nix config..."
    @nix --extra-experimental-features 'nix-command flakes' fmt
    @echo "✅  Nix config linted!"

[unix]
flake-update:
    @echo "🔄  Updating flake..."
    @nix --extra-experimental-features 'nix-command flakes' flake update --option access-tokens "github.com=$(gh auth token 2>/dev/null || echo '')"
    @echo "✅  Flake updated!"

# ── Build ────────────────────────────────────────────────────────────────

[macos]
build: system-info _check-maintenance
    @export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"; \
     nh darwin switch . --accept-flake-config

[linux]
build: system-info _check-maintenance
    @if uname -r | grep -q "WSL"; then \
      just _build-wsl; \
    elif [ "{{ arch() }}" = "aarch64" ]; then \
      just _build-bastion; \
    elif [ "{{ arch() }}" = "x86_64" ] && [ "$(hostname)" = "office-pc" ]; then \
      just _build-office-pc; \
    elif [ "{{ arch() }}" = "x86_64" ]; then \
      just _build-nixos; \
    else \
      echo "❌  Error: Unsupported architecture: {{ arch() }}"; \
      exit 1; \
    fi

[private]
_build-wsl:
    @echo "🔨  Building for WSL 🪟..."
    @export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"; \
     nh os switch . -H joe-wsl --accept-flake-config
    @echo "✅  Built for WSL!"

[private]
_build-bastion:
    @echo "🔨  Building for Oracle Cloud bastion 🐧..."
    @export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"; \
     nh os switch . -H oracle-cloud-bastion --accept-flake-config
    @echo "✅  Built for Oracle Cloud!"

[private]
_build-office-pc:
    @echo "🔨  Building for office PC 🐧..."
    @export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"; \
     nh os switch . -H office-pc --accept-flake-config
    @echo "✅  Built for office PC!"

[private]
_build-nixos:
    @echo "🔨  Building for NixOS desktop 🐧..."
    @export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"; \
     nh os switch . -H joe-desktop --accept-flake-config
    @echo "✅  Built for NixOS!"

# ── macOS-specific ───────────────────────────────────────────────────────

[macos]
build-macos-initial:
    @echo "🔨  Building Nix config for macOS 🍎 (initial)..."
    sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#Joes-MacBook-Pro
    @echo "✅  Built for macOS!"

[macos]
organize-launchpad:
    @echo "🔨  Organizing Launchpad..."
    @lporg load --config $(pwd)/hosts/common/system/dotconfig/lporg.yaml --yes --no-backup
    @echo "✅  Organized Launchpad!"

[macos]
save-launchpad:
    @echo "💾  Saving Launchpad..."
    @lporg save --config $(pwd)/hosts/common/system/dotconfig/lporg.yaml
    @echo "✅  Saved Launchpad!"

# ── Install ─────────────────────────────────────────────────────────────
# Usage: boot generic NixOS ISO, clone dotfiles, then:
#   nix-shell -p just
#   just install-office-pc

[unix]
install-office-pc:
    #!/usr/bin/env bash
    set -euo pipefail

    NEW_KEY_ID=""
    if gh auth status &>/dev/null; then
      echo "Already authenticated with GitHub."
      # Ensure we have the required scopes for listing/deleting SSH keys
      if ! gh api /user/keys &>/dev/null || ! gh api /user/ssh_signing_keys &>/dev/null; then
        echo "Missing required scopes, refreshing..."
        gh auth refresh -s admin:public_key -s admin:ssh_signing_key
      fi
      echo ""
      echo "SSH keys on your account:"
      gh ssh-key list
      echo ""
      read -p "Enter key ID to delete after install (or leave blank to skip): " NEW_KEY_ID
    else
      echo "Authenticating with GitHub..."
      KEYS_BEFORE=$(gh api /user/keys --jq '.[].id' 2>/dev/null || true)
      gh auth login -p ssh -s admin:public_key -s admin:ssh_signing_key
      KEYS_AFTER=$(gh api /user/keys --jq '.[].id')
      NEW_KEY_ID=$(comm -13 <(echo "$KEYS_BEFORE" | sort) <(echo "$KEYS_AFTER" | sort))
    fi

    if findmnt /mnt &>/dev/null; then
      echo "Disk already mounted at /mnt, skipping format."
    else
      read -p "This will ERASE /dev/nvme1n1. Continue? [y/N] " CONFIRM
      if [[ "$CONFIRM" != [yY] ]]; then
        echo "Aborted."
        exit 1
      fi
      read -s -p "Enter LUKS password: " LUKS_PASS
      echo
      read -s -p "Confirm LUKS password: " LUKS_PASS2
      echo
      if [ "$LUKS_PASS" != "$LUKS_PASS2" ]; then
        echo "Passwords do not match!"
        exit 1
      fi
      echo "$LUKS_PASS" > /tmp/luks-password

      echo "Partitioning /dev/nvme1n1 with disko..."
      sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko --accept-flake-config -- --mode destroy,format,mount --yes-wipe-all-disks ./hosts/office-pc/disk-config.nix

      rm -f /tmp/luks-password
    fi

    echo "Installing NixOS..."
    NIX_CONFIG="extra-experimental-features = nix-command flakes"
    NIX_CONFIG="$NIX_CONFIG"$'\n'"access-tokens = github.com=$(gh auth token)"
    NIX_CONFIG="$NIX_CONFIG"$'\n'"accept-flake-config = true"
    export NIX_CONFIG
    # Copy SSH key to root so nixos-install can fetch private submodules
    sudo mkdir -p /root/.ssh
    sudo cp ~/.ssh/id_ed25519 /root/.ssh/
    sudo chmod 600 /root/.ssh/id_ed25519
    sudo ssh-keyscan github.com 2>/dev/null | sudo tee /root/.ssh/known_hosts >/dev/null
    # Use target disk for nix store writes (overlay over ISO's read-only store)
    sudo mkdir -p /mnt/tmp /mnt/nix-store-overlay/upper /mnt/nix-store-overlay/work
    export TMPDIR=/mnt/tmp
    sudo mount -t overlay overlay -o lowerdir=/nix/store,upperdir=/mnt/nix-store-overlay/upper,workdir=/mnt/nix-store-overlay/work /nix/store
    ulimit -n 1048576
    echo "Building NixOS configuration..."
    sudo --preserve-env=NIX_CONFIG,TMPDIR nix build .#nixosConfigurations.office-pc.config.system.build.toplevel --log-format internal-json -v 2>&1 | nix run nixpkgs#nix-output-monitor -- --json
    echo "Installing NixOS to /mnt..."
    sudo --preserve-env=NIX_CONFIG,TMPDIR nixos-install --flake .#office-pc --no-root-passwd --no-channel-copy

    # Clean up overlay and tmp from target disk
    sudo umount /nix/store || true
    sudo rm -rf /mnt/nix-store-overlay /mnt/tmp

    if [ -n "$NEW_KEY_ID" ]; then
      echo "Removing temporary SSH key from GitHub"
      gh ssh-key delete "$NEW_KEY_ID" --yes
    fi

    echo "Done! You can reboot now."

# ── Remote hosts ─────────────────────────────────────────────────────────

[unix]
deploy-racknerd IP:
    @echo "🚀  Deploying Nix config to RackNerd VPS..."
    , nixos-anywhere --flake .#racknerd-cloud-agent --build-on local joe@{{ IP }}
    @echo "✅  Deployed to RackNerd VPS!"

[unix]
rebuild-racknerd:
    @echo "🔨  Rebuilding NixOS on RackNerd VPS..."
    @export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"; \
     nh os switch . -H racknerd-cloud-agent --accept-flake-config
    @echo "✅  Rebuilt RackNerd VPS!"

# ── Package management ───────────────────────────────────────────────────

[unix]
update-pins dry_run='':
    @echo "🔄  Updating pinned flake inputs..."
    @export GH_TOKEN="$(gh auth token 2>/dev/null || echo '')"; \
     {{ if dry_run == "--dry-run" { "DRY_RUN=true" } else { "" } }} scripts/update-flake-pins.sh
    @{{ if dry_run == "--dry-run" { "true" } else { "just _record-history update-pins" } }}
    @echo "✅  Pins updated!"
    just flake-update

[unix]
setup-python-packages packages='':
    @echo "🔄  Setting up Python packages..."
    @scripts/setup-python-packages.sh {{ packages }}
    @echo "✅  Python packages setup!"

[unix]
update-python-packages:
    @echo "🔄  Updating Python packages..."
    @scripts/update-python-packages.sh --no-build
    @echo "✅  Python packages updated!"

[unix]
update-node-packages:
    @echo "🔄  Updating Node packages..."
    @scripts/update-node-packages.sh
    @echo "✅  Node packages updated!"

# ── Maintenance ──────────────────────────────────────────────────────────

[unix]
nix-gc:
    @echo "🧹  Garbage collecting nix..."
    @nh clean all --keep-since 7d --keep 3
    @echo "✅  Garbage collected!"

# ── Submodules ───────────────────────────────────────────────────────

[unix]
sync-submodules:
    @echo "🔄  Syncing submodules..."
    @git submodule sync --recursive
    @git submodule update --init --recursive --remote
    @just _record-history sync-submodules
    @echo "✅  Submodules synced!"

# ── History tracking ─────────────────────────────────────────────────

history_file := ".history"
stale_days := "7"

[private]
_record-history task:
    @touch {{ history_file }}
    @grep -v "^{{ task }}:" {{ history_file }} > {{ history_file }}.tmp 2>/dev/null || true
    @echo "{{ task }}:$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> {{ history_file }}.tmp
    @mv {{ history_file }}.tmp {{ history_file }}

[private]
_check-maintenance:
    #!/usr/bin/env bash
    history_file="{{ history_file }}"
    stale_seconds=$(( {{ stale_days }} * 86400 ))
    now=$(date +%s)
    check_task() {
      local task=$1 label=$2 cmd=$3
      local last=""
      if [[ -f "$history_file" ]]; then
        last=$(grep "^${task}:" "$history_file" 2>/dev/null | cut -d: -f2- || true)
      fi
      if [[ -z "$last" ]]; then
        echo -e "\033[0;33m[WARN]\033[0m $label has never been run — consider: just $cmd"
      else
        local last_ts
        last_ts=$(date -d "$last" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last" +%s 2>/dev/null || echo 0)
        local age=$(( now - last_ts ))
        if (( age > stale_seconds )); then
          local days_ago=$(( age / 86400 ))
          echo -e "\033[0;33m[WARN]\033[0m $label last run ${days_ago}d ago — consider: just $cmd"
        fi
      fi
    }
    check_task "update-pins" "Pin updates" "update-pins"
    check_task "sync-submodules" "Submodule sync" "sync-submodules"
