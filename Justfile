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
    elif [ "{{ arch() }}" = "x86_64" ] && [ "$(hostname)" = "racknerd-cloud-agent" ]; then \
      just _build-racknerd; \
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
_build-racknerd:
    @echo "🔨  Building for RackNerd VPS 🐧..."
    @export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"; \
     nh os switch . -H racknerd-cloud-agent --accept-flake-config
    @echo "✅  Built for RackNerd!"

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

# ── ISO images ──────────────────────────────────────────────────────────

[unix]
build-office-pc-iso:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Decrypting attic netrc from 1Password..."
    trap 'rm -f /tmp/attic-netrc' EXIT
    scripts/secret-helper.sh decrypt attic-netrc /tmp/attic-netrc
    echo "Building office-pc installer ISO..."
    nix build .#nixosConfigurations.office-pc-installer.config.system.build.isoImage --impure --log-format internal-json -v |& nom --json
    rm -f /tmp/attic-netrc
    echo "ISO built: $(ls result/iso/*.iso)"

[unix, confirm("This will ERASE the target device. Continue?")]
write-iso device="":
    #!/usr/bin/env bash
    set -euo pipefail
    ISO=$(ls result/iso/*.iso 2>/dev/null | head -1)
    if [ -z "$ISO" ]; then
      echo "No ISO found. Run 'just build-office-pc-iso' first."
      exit 1
    fi
    DEV="{{ device }}"
    if [ -z "$DEV" ]; then
      if lsblk /dev/sdb &>/dev/null; then
        echo "Found /dev/sdb:"
        lsblk /dev/sdb
        DEV="/dev/sdb"
      else
        echo "No device specified and /dev/sdb not found."
        echo "Usage: just write-iso /dev/sdX"
        exit 1
      fi
    fi
    DEV=$(echo "$DEV" | sed 's/[0-9]*$//')
    echo "Writing $ISO -> $DEV"
    for part in $(lsblk -ln -o NAME "$DEV" | tail -n +2); do
      if mountpoint -q "/dev/$part" 2>/dev/null || findmnt "/dev/$part" &>/dev/null; then
        echo "Unmounting /dev/$part..."
        sudo umount "/dev/$part" || true
      fi
    done
    sudo dd if="$ISO" of="$DEV" bs=4M status=progress oflag=sync
    echo "ISO written to $DEV"

# ── Secrets ──────────────────────────────────────────────────────────────

[unix]
secret *args:
    @scripts/secret-helper.sh {{ args }}

# ── Remote hosts ─────────────────────────────────────────────────────────

[unix]
deploy-racknerd IP:
    @echo "🚀  Deploying Nix config to RackNerd VPS..."
    , nixos-anywhere --flake .#racknerd-cloud-agent --build-on local joe@{{ IP }}
    @echo "✅  Deployed to RackNerd VPS!"

[unix]
rebuild-racknerd:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on RackNerd VPS (build locally, deploy remote)..."
    DOMAINS="import ./secrets/domains.nix"
    SSH_DOMAIN=$(nix eval --impure --expr "($DOMAINS).racknerdSshDomain" --raw)
    SSH_USER=$(nix eval --impure --expr "($DOMAINS).sshUser" --raw)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nixos-rebuild switch --flake .#racknerd-cloud-agent --target-host "$SSH_USER@$SSH_DOMAIN" --build-host localhost --use-remote-sudo --accept-flake-config --log-format internal-json -v |& nom --json
    echo "✅  Rebuilt RackNerd VPS!"

[unix]
rebuild-bastion:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on Oracle Cloud bastion (build locally, deploy remote)..."
    DOMAINS="import ./secrets/domains.nix"
    BASTION_DOMAIN=$(nix eval --impure --expr "($DOMAINS).bastionDomain" --raw)
    SSH_USER=$(nix eval --impure --expr "($DOMAINS).sshUser" --raw)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nixos-rebuild switch --flake .#oracle-cloud-bastion --target-host "$SSH_USER@$BASTION_DOMAIN" --build-host localhost --use-remote-sudo --accept-flake-config --log-format internal-json -v |& nom --json
    echo "✅  Rebuilt Oracle Cloud bastion!"

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
