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
    #!/usr/bin/env bash
    just _show-build-prediction "darwin"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nh darwin switch . --accept-flake-config
    just _finish-build "darwin" "$start" $?

[linux]
build: system-info _check-maintenance
    @if uname -r | grep -q "WSL"; then \
      just _build-wsl; \
    elif [ "{{ arch() }}" = "aarch64" ]; then \
      just _build-bastion; \
    elif [ "{{ arch() }}" = "x86_64" ] && [ "$(hostname)" = "joe-steamdeck" ]; then \
      just _build-steamdeck; \
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
    #!/usr/bin/env bash
    echo "🔨  Building for WSL 🪟..."
    just _show-build-prediction "joe-wsl"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nh os switch . -H joe-wsl --accept-flake-config
    just _finish-build "joe-wsl" "$start" $?

[private]
_build-bastion:
    #!/usr/bin/env bash
    echo "🔨  Building for Oracle Cloud bastion 🐧..."
    just _show-build-prediction "oracle-cloud-bastion"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nh os switch . -H oracle-cloud-bastion --accept-flake-config
    just _finish-build "oracle-cloud-bastion" "$start" $?

[private]
_build-office-pc:
    #!/usr/bin/env bash
    echo "🔨  Building for office PC 🐧..."
    just _show-build-prediction "office-pc"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nh os switch . -H office-pc --accept-flake-config
    just _finish-build "office-pc" "$start" $?

[private]
_build-racknerd:
    #!/usr/bin/env bash
    echo "🔨  Building for RackNerd VPS 🐧..."
    just _show-build-prediction "racknerd-cloud-agent"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nh os switch . -H racknerd-cloud-agent --accept-flake-config
    just _finish-build "racknerd-cloud-agent" "$start" $?

[private]
_build-steamdeck:
    #!/usr/bin/env bash
    echo "🔨  Building for Steam Deck 🎮..."
    just _show-build-prediction "joe-steamdeck"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nh os switch . -H joe-steamdeck --accept-flake-config
    just _finish-build "joe-steamdeck" "$start" $?

[private]
_build-nixos:
    #!/usr/bin/env bash
    echo "🔨  Building for NixOS desktop 🐧..."
    just _show-build-prediction "joe-desktop"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nh os switch . -H joe-desktop --accept-flake-config
    just _finish-build "joe-desktop" "$start" $?

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
    @scripts/secret-helper.sh {{ args }}

# ── Remote hosts ─────────────────────────────────────────────────────────

[unix]
deploy-racknerd IP:
    @echo "🚀  Deploying Nix config to RackNerd VPS..."
    , nixos-anywhere --flake .#racknerd-cloud-agent --build-on local joe@{{ IP }}
    @echo "✅  Deployed to RackNerd VPS!"

[unix]
build-to-racknerd:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on RackNerd VPS (build locally, deploy remote)..."
    DOMAINS="import ./secrets/domains.nix"
    SSH_DOMAIN=$(nix eval --impure --expr "($DOMAINS).racknerdSshDomain" --raw)
    SSH_USER=$(nix eval --impure --expr "($DOMAINS).sshUser" --raw)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nixos-rebuild switch --flake .#racknerd-cloud-agent --target-host "$SSH_USER@$SSH_DOMAIN" --build-host localhost --sudo --accept-flake-config --log-format internal-json -v |& nom --json
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
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔄  Syncing submodules..."
    git submodule sync --recursive
    # First pass: push local commits and check for problems
    git submodule foreach --recursive '
      git fetch origin 2>/dev/null || { echo "❌  $name: failed to fetch — aborting"; exit 1; }
      local_ahead="$(git log --oneline @{u}..HEAD 2>/dev/null || true)"
      remote_ahead="$(git log --oneline HEAD..@{u} 2>/dev/null || true)"
      dirty="$(git status --porcelain 2>/dev/null || true)"
      if [ -n "$dirty" ]; then
        echo "❌  $name: has uncommitted changes — aborting"
        exit 1
      fi
      if [ -n "$local_ahead" ] && [ -n "$remote_ahead" ]; then
        echo "❌  $name: local and remote have diverged — aborting (resolve manually)"
        exit 1
      fi
      if [ -n "$local_ahead" ]; then
        echo "  ⬆️  Pushing $name..."
        git push || { echo "❌  $name: push failed — aborting"; exit 1; }
      fi
    '
    # Second pass: pull remote updates
    git submodule update --init --recursive --remote
    # Third pass: re-resolve transitive flake deps from path: submodules
    # (e.g. agent-skills pins codex-nix/claude-nix/gemini-nix which the
    #  outer dotfiles lock caches independently)
    echo "🔒  Re-locking transitive flake deps from submodules..."
    git submodule foreach --quiet 'echo "$name"' | while read -r sub; do
      for dep in $(nix flake metadata --json "path:./$sub" 2>/dev/null \
                    | jq -r '.locks.nodes.root.inputs // {} | keys[]' 2>/dev/null); do
        nix flake lock --update-input "$sub/$dep" 2>/dev/null || true
      done
    done
    just _record-history sync-submodules
    echo "✅  Submodules synced!"

# ── Build timing ─────────────────────────────────────────────────────

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
    file="{{ build_times_file }}"
    touch "$file"
    # Keep last 5 entries per host
    existing=$(grep "^{{ host }}:" "$file" 2>/dev/null | tail -4)
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
