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
build *args="": system-info _check-maintenance
    #!/usr/bin/env bash
    just _show-build-prediction "darwin"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    [ -n "{{args}}" ] && echo "📦  Extra nh args: {{args}}"
    nh darwin switch . --accept-flake-config {{args}}
    just _finish-build "darwin" "$start" $?

[linux]
build *args="": system-info _check-maintenance
    @if [ "{{ arch() }}" = "aarch64" ]; then \
      just _build-bastion {{args}}; \
    elif [ "{{ arch() }}" = "x86_64" ] && [ "$(hostname)" = "joe-steamdeck" ]; then \
      just _build-steamdeck {{args}}; \
    elif [ "{{ arch() }}" = "x86_64" ] && [ "$(hostname)" = "office-pc" ]; then \
      just _build-office-pc {{args}}; \
    elif [ "{{ arch() }}" = "x86_64" ] && [ "$(hostname)" = "racknerd-cloud-agent" ]; then \
      just _build-racknerd {{args}}; \
    elif [ "{{ arch() }}" = "x86_64" ] && [ "$(hostname)" = "cloud-proxy" ]; then \
      just _build-cloud-proxy {{args}}; \
    elif [ "{{ arch() }}" = "x86_64" ]; then \
      just _build-nixos {{args}}; \
    else \
      echo "❌  Error: Unsupported architecture: {{ arch() }}"; \
      exit 1; \
    fi

[private]
_build-bastion *args="":
    #!/usr/bin/env bash
    echo "🔨  Building for Oracle Cloud bastion 🐧..."
    just _show-build-prediction "oracle-cloud-bastion"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    [ -n "{{args}}" ] && echo "📦  Extra nh args: {{args}}"
    nh os switch . -H oracle-cloud-bastion --accept-flake-config {{args}}
    just _finish-build "oracle-cloud-bastion" "$start" $?

[private]
_build-office-pc *args="":
    #!/usr/bin/env bash
    echo "🔨  Building for office PC 🐧..."
    just _show-build-prediction "office-pc"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    [ -n "{{args}}" ] && echo "📦  Extra nh args: {{args}}"
    nh os switch . -H office-pc --accept-flake-config {{args}}
    just _finish-build "office-pc" "$start" $?

[private]
_build-racknerd *args="":
    #!/usr/bin/env bash
    echo "🔨  Building for RackNerd VPS 🐧..."
    just _show-build-prediction "racknerd-cloud-agent"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    [ -n "{{args}}" ] && echo "📦  Extra nh args: {{args}}"
    nh os switch . -H racknerd-cloud-agent --accept-flake-config {{args}}
    just _finish-build "racknerd-cloud-agent" "$start" $?

[private]
_build-cloud-proxy *args="":
    #!/usr/bin/env bash
    echo "🔨  Building for cloud-proxy VPS 🐧..."
    just _show-build-prediction "cloud-proxy"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    [ -n "{{args}}" ] && echo "📦  Extra nh args: {{args}}"
    nh os switch . -H cloud-proxy --accept-flake-config {{args}}
    just _finish-build "cloud-proxy" "$start" $?

[private]
_build-steamdeck *args="":
    #!/usr/bin/env bash
    echo "🔨  Building for Steam Deck 🎮..."
    just _show-build-prediction "joe-steamdeck"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    [ -n "{{args}}" ] && echo "📦  Extra nh args: {{args}}"
    nh os switch . -H joe-steamdeck --accept-flake-config {{args}}
    just _finish-build "joe-steamdeck" "$start" $?

[private]
_build-nixos *args="":
    #!/usr/bin/env bash
    echo "🔨  Building for NixOS desktop 🐧..."
    just _show-build-prediction "joe-desktop"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    [ -n "{{args}}" ] && echo "📦  Extra nh args: {{args}}"
    nh os switch . -H joe-desktop --accept-flake-config {{args}}
    just _finish-build "joe-desktop" "$start" $?

# ── macOS-specific ───────────────────────────────────────────────────────

[macos]
build-macos-initial:
    @echo "🔨  Building Nix config for macOS 🍎 (initial)..."
    sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#Joes-MacBook-Pro
    @echo "✅  Built for macOS!"

# ── ISO images ──────────────────────────────────────────────────────────

[unix]
build-office-pc-iso:
    @echo "Building office-pc installer ISO (includes full system closure)..."
    @nix build .#nixosConfigurations.office-pc-installer.config.system.build.isoImage --log-format internal-json -v |& nom --json
    echo "ISO built: $(ls result/iso/*.iso)"

[confirm("This will ERASE the target device. Continue?")]
[unix]
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
    ISO_SIZE=$(stat --format=%s "$ISO" 2>/dev/null || stat -f%z "$ISO")
    ISO_SIZE_MB=$(( ISO_SIZE / 1024 / 1024 ))
    echo "Writing $ISO (${ISO_SIZE_MB}MB) -> $DEV"
    for part in $(lsblk -ln -o NAME "$DEV" | tail -n +2); do
      if mountpoint -q "/dev/$part" 2>/dev/null || findmnt "/dev/$part" &>/dev/null; then
        echo "Unmounting /dev/$part..."
        sudo umount "/dev/$part" || true
      fi
    done
    START=$(date +%s)
    if command -v pv &>/dev/null; then
      pv -petab -s "$ISO_SIZE" < "$ISO" | sudo dd of="$DEV" bs=4M oflag=sync 2>/dev/null
    else
      sudo dd if="$ISO" of="$DEV" bs=4M status=progress oflag=sync
    fi
    ELAPSED=$(( $(date +%s) - START ))
    MINS=$(( ELAPSED / 60 ))
    SECS=$(( ELAPSED % 60 ))
    echo "✅  ISO written to $DEV in ${MINS}m${SECS}s"

# ── Secrets ──────────────────────────────────────────────────────────────

[unix]
secret *args:
    @secret-helper {{ args }}

# ── Remote hosts ─────────────────────────────────────────────────────────

[unix]
deploy-racknerd IP:
    @echo "🚀  Deploying Nix config to RackNerd VPS..."
    , nixos-anywhere --flake .#racknerd-cloud-agent --build-on local joe@{{ IP }}
    @echo "✅  Deployed to RackNerd VPS!"

[unix]
deploy-cloud-proxy IP USER="ubuntu":
    @echo "🚀  Deploying Nix config to cloud-proxy VPS..."
    , nixos-anywhere --flake .#cloud-proxy --build-on local {{ USER }}@{{ IP }}
    @echo "✅  Deployed to cloud-proxy VPS!"

[unix]
build-to-cloud-proxy:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on cloud-proxy VPS (build locally, deploy remote)..."
    DOMAINS="import ./secrets/domains.nix"
    SSH_DOMAIN=$(nix eval --impure --expr "($DOMAINS).cloudProxySshDomain" --raw)
    SSH_USER=$(nix eval --impure --expr "($DOMAINS).sshUser" --raw)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nixos-rebuild switch --flake .#cloud-proxy --target-host "$SSH_USER@$SSH_DOMAIN" --build-host localhost --sudo --accept-flake-config --log-format internal-json -v |& nom --json
    echo "✅  Rebuilt cloud-proxy VPS!"

[unix]
build-to-racknerd:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on RackNerd VPS (build locally, deploy remote)..."
    DOMAINS="import ./secrets/domains.nix"
    SSH_DOMAIN=$(nix eval --impure --expr "($DOMAINS).racknerdSshDomain" --raw)
    SSH_USER=$(nix eval --impure --expr "($DOMAINS).sshUser" --raw)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nixos-rebuild switch --flake .#racknerd-cloud-agent --target-host "$SSH_USER@$SSH_DOMAIN" --build-host localhost --sudo --accept-flake-config --fallback --log-format internal-json -v |& nom --json
    echo "✅  Rebuilt RackNerd VPS!"

[unix]
build-to-bastion local="":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on Oracle Cloud bastion..."
    DOMAINS="import ./secrets/domains.nix"
    BASTION_DOMAIN=$(nix eval --impure --expr "($DOMAINS).bastionDomain" --raw)
    SSH_USER=$(nix eval --impure --expr "($DOMAINS).sshUser" --raw)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    BUILD_HOST_ARGS=()
    if [ "{{ local }}" = "--local" ]; then
      BUILD_HOST_ARGS=(--build-host localhost)
    fi
    nixos-rebuild switch --flake .#oracle-cloud-bastion --target-host "$SSH_USER@$BASTION_DOMAIN" "${BUILD_HOST_ARGS[@]}" --sudo --ask-sudo-password --accept-flake-config
    echo "✅  Rebuilt Oracle Cloud bastion!"

# ── Package management ───────────────────────────────────────────────────

[unix]
setup-python-packages packages='':
    @echo "🔄  Setting up Python packages..."
    @setup-python-packages {{ packages }}
    @echo "✅  Python packages setup!"

[unix]
update-python-packages:
    @echo "🔄  Updating Python packages..."
    @update-python-packages --no-build
    @echo "✅  Python packages updated!"

# ── Maintenance ──────────────────────────────────────────────────────────

[unix]
nix-gc:
    @echo "🧹  Garbage collecting nix..."
    @nh clean all --keep-since 7d --keep 3
    @echo "✅  Garbage collected!"


# ── Build timing ─────────────────────────────────────────────────────

# Per-machine build durations, kept local (gitignored). Predictions are
# per-host and read straight from this file — nothing to sync anywhere.
build_times_file := ".build-times"

[private]
_show-build-prediction host:
    #!/usr/bin/env bash
    file="{{ build_times_file }}"
    if [[ ! -f "$file" ]]; then exit 0; fi
    times=$(grep "^{{ host }}:" "$file" 2>/dev/null | cut -d: -f2)
    if [[ -z "$times" ]]; then exit 0; fi
    last=$(echo "$times" | tail -1)
    avg=$(echo "$times" | awk '{s+=$1; n++} END {printf "%.0f", s/n}')
    fmt_time() {
      local s=$1
      if (( s >= 60 )); then
        printf "%dm%02ds" $((s/60)) $((s%60))
      else
        printf "%ds" "$s"
      fi
    }
    echo "⏱ est. $(fmt_time $last) (∅ $(fmt_time $avg))"

[private]
_record-build-time host seconds:
    #!/usr/bin/env bash
    set -euo pipefail
    file="{{ build_times_file }}"
    mkdir -p "$(dirname "$file")"
    touch "$file"
    # Keep last 5 entries per host. grep+tail returns 1 when there's no
    # prior entry (first build for this host), so swallow the exit code.
    existing=$(grep "^{{ host }}:" "$file" 2>/dev/null | tail -4 || true)
    grep -v "^{{ host }}:" "$file" > "$file.tmp" 2>/dev/null || true
    if [[ -n "$existing" ]]; then
      echo "$existing" >> "$file.tmp"
    fi
    echo "{{ host }}:{{ seconds }}" >> "$file.tmp"
    mv "$file.tmp" "$file"

[private]
_finish-build host start_time exit_code:
    #!/usr/bin/env bash
    elapsed=$(( $(date +%s) - {{ start_time }} ))
    if (( elapsed >= 60 )); then
      fmt=$(printf "%dm%02ds" $((elapsed/60)) $((elapsed%60)))
    else
      fmt="${elapsed}s"
    fi
    if [[ {{ exit_code }} -eq 0 ]]; then
      just _record-build-time "{{ host }}" "$elapsed"
      echo "✅  Built! ⏱️  ${fmt}"
    else
      echo "❌  Build failed after ⏱️  ${fmt}"
      exit {{ exit_code }}
    fi

# ── Maintenance reminders ────────────────────────────────────────────

stale_days := "7"

[private]
_check-maintenance:
    #!/usr/bin/env bash
    stale_seconds=$(( {{ stale_days }} * 86400 ))
    now=$(date +%s)
    # Freshness comes from the artifact itself: flake-update keeps flake.lock
    # fresh → newest input's lastModified.
    check_task() {
      local label=$1 cmd=$2 last_ts=$3
      if [[ -z "$last_ts" ]]; then
        echo -e "\033[0;33m[WARN]\033[0m $label has never been run — consider: just $cmd"
      elif (( now - last_ts > stale_seconds )); then
        echo -e "\033[0;33m[WARN]\033[0m $label last refreshed $(( (now - last_ts) / 86400 ))d ago — consider: just $cmd"
      fi
    }
    pins_ts=$(jq -r '[.nodes[].locked.lastModified // empty] | max // empty' flake.lock 2>/dev/null || true)
    check_task "Flake inputs" "flake-update" "$pins_ts"
