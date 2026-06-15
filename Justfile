[private]
default: system-info
    @just --list

# Show architecture and OS for this machine
system-info:
    @echo "🖥️  This is an {{ arch() }} machine on {{ os() }}"

# ── Build & activate (this machine) ──────────────────────────────────────
# build = build only, boot = activate at next boot, switch = activate now.
# All three resolve the host from arch/hostname and run through _nh-os.

# Build the system closure without activating
[linux]
build *args="": (_nh-os "build" args)

# Build and set as the bootloader default (takes effect next reboot)
[linux]
boot *args="": (_nh-os "boot" args)

# Build and activate immediately
[linux]
switch *args="": (_nh-os "switch" args)

# Build the darwin closure without activating
[macos]
build *args="": (_nh-darwin "build" args)

[macos]
boot *args="":
    @echo "❌  nix-darwin has no boot activation; use just build or just switch"
    @exit 1

# Build and activate immediately
[macos]
switch *args="": (_nh-darwin "switch" args)

[private]
[linux]
_nh-os action *args="": system-info _check-maintenance
    #!/usr/bin/env bash
    if [ "{{ arch() }}" = "aarch64" ]; then
      host=oracle-cloud-bastion
    else
      case "$(hostname)" in
        joe-steamdeck | office-pc | racknerd-cloud-agent | cloud-proxy) host="$(hostname)" ;;
        *) host=joe-desktop ;;
      esac
    fi
    echo "🔨  nh os {{ action }} for $host 🐧..."
    just _show-build-prediction "$host"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    [ -n "{{ args }}" ] && echo "📦  Extra nh args: {{ args }}"
    nh os {{ action }} . -H "$host" --accept-flake-config {{ args }}
    just _finish-build "$host" "$start" $?

[private]
[macos]
_nh-darwin action *args="": system-info _check-maintenance
    #!/usr/bin/env bash
    echo "🔨  nh darwin {{ action }} 🍎..."
    just _show-build-prediction "darwin"
    start=$(date +%s)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    [ -n "{{ args }}" ] && echo "📦  Extra nh args: {{ args }}"
    nh darwin {{ action }} . --accept-flake-config {{ args }}
    just _finish-build "darwin" "$start" $?

# ── Remote rebuilds (existing hosts) ──────────────────────────────────────
# Domains/users come from the dotfiles-secrets flake input via _secret-domain.

# Rebuild cloud-proxy in place (build locally, deploy over ssh)
[unix]
build-to-cloud-proxy:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on cloud-proxy VPS (build locally, deploy remote)..."
    SSH_DOMAIN=$(just _secret-domain cloudProxySshDomain)
    SSH_USER=$(just _secret-domain sshUser)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nixos-rebuild switch --flake .#cloud-proxy --target-host "$SSH_USER@$SSH_DOMAIN" --build-host localhost --sudo --accept-flake-config --log-format internal-json -v |& nom --json
    echo "✅  Rebuilt cloud-proxy VPS!"

# Rebuild racknerd in place (build locally, deploy over ssh)
[unix]
build-to-racknerd:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on RackNerd VPS (build locally, deploy remote)..."
    SSH_DOMAIN=$(just _secret-domain racknerdSshDomain)
    SSH_USER=$(just _secret-domain sshUser)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nixos-rebuild switch --flake .#racknerd-cloud-agent --target-host "$SSH_USER@$SSH_DOMAIN" --build-host localhost --sudo --accept-flake-config --fallback --log-format internal-json -v |& nom --json
    echo "✅  Rebuilt RackNerd VPS!"

# Rebuild the bastion in place (pass --local to build on this machine)
[unix]
build-to-bastion local="":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on Oracle Cloud bastion..."
    BASTION_DOMAIN=$(just _secret-domain bastionDomain)
    SSH_USER=$(just _secret-domain sshUser)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    BUILD_HOST_ARGS=()
    if [ "{{ local }}" = "--local" ]; then
      BUILD_HOST_ARGS=(--build-host localhost)
    fi
    nixos-rebuild switch --flake .#oracle-cloud-bastion --target-host "$SSH_USER@$BASTION_DOMAIN" "${BUILD_HOST_ARGS[@]}" --sudo --ask-sudo-password --accept-flake-config
    echo "✅  Rebuilt Oracle Cloud bastion!"

# ── Bootstrap (first deploy onto a fresh machine) ─────────────────────────

# Install NixOS onto a fresh RackNerd VPS via nixos-anywhere
[unix]
deploy-racknerd IP:
    @echo "🚀  Deploying Nix config to RackNerd VPS..."
    , nixos-anywhere --flake .#racknerd-cloud-agent --build-on local joe@{{ IP }}
    @echo "✅  Deployed to RackNerd VPS!"

# Install NixOS onto a fresh cloud-proxy VPS via nixos-anywhere
[unix]
deploy-cloud-proxy IP USER="ubuntu":
    @echo "🚀  Deploying Nix config to cloud-proxy VPS..."
    , nixos-anywhere --flake .#cloud-proxy --build-on local {{ USER }}@{{ IP }}
    @echo "✅  Deployed to cloud-proxy VPS!"

# First darwin activation on a fresh mac (before nh exists)
[macos]
build-macos-initial:
    @echo "🔨  Building Nix config for macOS 🍎 (initial)..."
    sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#Joes-MacBook-Pro
    @echo "✅  Built for macOS!"

# ── Installer ISO (office-pc) ──────────────────────────────────────────────

# Build the offline installer ISO with the full office-pc closure baked in
[unix]
build-office-pc-iso:
    @echo "Building office-pc installer ISO (includes full system closure)..."
    @nix build .#nixosConfigurations.office-pc-installer.config.system.build.isoImage --log-format internal-json -v |& nom --json
    echo "ISO built: $(ls result/iso/*.iso)"

# Write the built ISO to a USB device (defaults to /dev/sdb)
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

# ── Raspberry Pi SD image (crawler) ────────────────────────────────────────

# Cross-builds aarch64 via binfmt on x86_64; builds natively on aarch64.
# --accept-flake-config trusts the nixos-raspberrypi cachix substituter.
# --fallback builds from source when a substituter serves a corrupt/partial NAR
# (e.g. the attic cache occasionally truncates firmware/zfs-user NARs).
# Build the crawler SD-card image (uncompressed .img)
[unix]
build-crawler-image:
    @echo "🔨  Building crawler SD image (aarch64; builds the rpi kernel if not cached)..."
    @nix build .#nixosConfigurations.crawler.config.system.build.sdImage --accept-flake-config --fallback --log-format internal-json -v |& nom --json
    @echo "✅  Image built: $(ls result/sd-image/*.img)"

# Bake the SSH host key into the built image's ext4 root and emit a standalone,
# ready-to-flash .img — no block device is touched. Pure userspace (debugfs), so
# it needs no root, no loopback, and no mount: runs on macOS and Linux alike
# (macOS can't mount ext4, but debugfs writes it directly).
# The host key is pulled from 1Password (item "Crawler RasPi Nixos SSH Key" in
# vault "Private", fields "private key"/"public key"), the same way secret-helper
# sources keys via `op read`. The injected /etc/ssh/ssh_host_ed25519_key is the
# agenix identity that decrypts wifi/attic on first boot.
# Pass img= to bake an image built elsewhere; otherwise it auto-detects
# ./result/sd-image/*.img. Pass key=/path/to/privkey to read from disk instead
# of 1Password.
# Usage: just bake-crawler-image [out.img] [img=/path/to/raw.img] [item=] [vault=] [key=]
[unix]
bake-crawler-image out="crawler-sd.img" img="" item="Crawler RasPi Nixos SSH Key" vault="Private" key="":
    #!/usr/bin/env bash
    set -euo pipefail
    IMG="{{ img }}"
    if [ -z "$IMG" ]; then
      IMG=$(ls result/sd-image/*.img 2>/dev/null | head -1)
    fi
    if [ -z "$IMG" ] || [ ! -f "$IMG" ]; then
      echo "No image found. Pass img=/path/to/raw.img, or run 'just build-crawler-image' first."
      exit 1
    fi
    OUT="{{ out }}"

    # Resolve the host key into private/public temp files (mode 600, removed on
    # exit). Default source is 1Password; key= overrides with an on-disk privkey.
    PRIV=$(mktemp); PUB=$(mktemp)
    chmod 600 "$PRIV" "$PUB"
    trap 'rm -f "$PRIV" "$PUB"' EXIT
    KEY="{{ key }}"
    if [ -n "$KEY" ]; then
      [ -f "$KEY" ] || { echo "Key file '$KEY' not found"; exit 1; }
      cp "$KEY" "$PRIV"
      if [ -f "$KEY.pub" ]; then cp "$KEY.pub" "$PUB"; else ssh-keygen -y -f "$PRIV" > "$PUB"; fi
      echo "Using on-disk host key: $KEY"
    else
      command -v op >/dev/null 2>&1 || { echo "1Password CLI 'op' not found (needed to fetch the host key)"; exit 1; }
      echo "Fetching host key from 1Password: {{ item }} (vault {{ vault }})"
      op read "op://{{ vault }}/{{ item }}/private key?ssh-format=openssh" > "$PRIV"
      op read "op://{{ vault }}/{{ item }}/public key" > "$PUB"
      [ -s "$PRIV" ] && [ -s "$PUB" ] || { echo "Failed to read host key from 1Password"; exit 1; }
    fi

    # Copy the store image (0444) to a writable, user-owned file. Prefer a
    # copy-on-write clone (instant on APFS/btrfs); fall back to a full copy.
    echo "Copying image -> $OUT"
    if   cp --reflink=auto "$IMG" "$OUT" 2>/dev/null; then :
    elif cp -c             "$IMG" "$OUT" 2>/dev/null; then :
    else cp                "$IMG" "$OUT"; fi
    chmod u+w "$OUT"

    # Find the ext4 root partition (MBR type 0x83) and its byte offset. The MBR
    # partition table lives at byte 446; each 16-byte entry holds the type at
    # +4 and the little-endian start LBA at +8.
    OFF=""
    for slot in 0 1 2 3; do
      base=$((446 + slot * 16))
      ptype=$(dd if="$OUT" bs=1 skip=$((base + 4)) count=1 2>/dev/null | od -An -tu1 | tr -d ' ')
      if [ "$ptype" = "131" ]; then   # 0x83 = Linux
        start=$(dd if="$OUT" bs=1 skip=$((base + 8)) count=4 2>/dev/null | od -An -tu4 | tr -d ' ')
        OFF=$((start * 512))
        break
      fi
    done
    if [ -z "$OFF" ]; then
      echo "No Linux (ext4, type 0x83) partition found in $OUT"
      exit 1
    fi
    echo "ext4 root partition at byte offset $OFF — injecting host key via debugfs"

    # debugfs from e2fsprogs; use it from PATH if present, else from nixpkgs.
    DEBUGFS=(debugfs)
    command -v debugfs >/dev/null 2>&1 || DEBUGFS=(nix shell nixpkgs#e2fsprogs -c debugfs)

    # Inject the key into the ext4 root entirely in userspace at the partition
    # offset. NixOS generates most of /etc at boot but preserves pre-seeded
    # ssh_host_*_key files, so creating /etc/ssh here is enough.
    DBG=$(mktemp)
    cat > "$DBG" <<EOF
    mkdir /etc
    sif /etc mode 040755
    mkdir /etc/ssh
    sif /etc/ssh mode 040755
    cd /etc/ssh
    rm ssh_host_ed25519_key
    rm ssh_host_ed25519_key.pub
    write $PRIV ssh_host_ed25519_key
    write $PUB ssh_host_ed25519_key.pub
    sif ssh_host_ed25519_key mode 0100600
    sif ssh_host_ed25519_key uid 0
    sif ssh_host_ed25519_key gid 0
    sif ssh_host_ed25519_key.pub mode 0100644
    sif ssh_host_ed25519_key.pub uid 0
    sif ssh_host_ed25519_key.pub gid 0
    ls -l .
    EOF
    "${DEBUGFS[@]}" -w -f "$DBG" "$OUT?offset=$OFF"
    rm -f "$DBG"

    SIZE=$(du -h "$OUT" | cut -f1)
    echo "✅  Ready: $OUT (${SIZE}) — host key injected."
    echo "   Copy it to your Mac and write to the SD card, e.g.:"
    echo "     • Raspberry Pi Imager / Balena Etcher → choose 'Use custom' → $OUT"
    echo "     • or on macOS:  diskutil list   →   diskutil unmountDisk /dev/diskN"
    echo "                     sudo dd if=$OUT of=/dev/rdiskN bs=4M status=progress   (rdiskN = raw, faster)"

# ── Secrets & packages ─────────────────────────────────────────────────────

# Manage agenix secrets (add/edit/remove/decrypt/rekey/list)
[unix]
secret *args:
    @secret-helper {{ args }}

# Add PyPI packages to the custom python set
[unix]
setup-python-packages packages='':
    @echo "🔄  Setting up Python packages..."
    @setup-python-packages {{ packages }}
    @echo "✅  Python packages setup!"

# Bump versions/hashes of the custom PyPI package set
[unix]
update-python-packages:
    @echo "🔄  Updating Python packages..."
    @update-python-packages --no-build
    @echo "✅  Python packages updated!"

# ── Repo checks & maintenance ──────────────────────────────────────────────

# Run nix flake check for this system
[unix]
check: lint
    @echo "🔍  Checking Nix config for {{ arch() }}-{{ os() }}..."
    @NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_BROKEN=1 nix --extra-experimental-features 'nix-command flakes' flake check --impure --system {{ arch() }}-{{ os() }} --show-trace
    @echo "✅  Check completed!"

# Format all nix files (nixfmt)
[unix]
lint:
    @echo "📝  Linting Nix config..."
    @nix --extra-experimental-features 'nix-command flakes' fmt
    @echo "✅  Nix config linted!"

# Update every flake input (the lock is the only pin)
[unix]
flake-update:
    @echo "🔄  Updating flake..."
    @nix --extra-experimental-features 'nix-command flakes' flake update --option access-tokens "github.com=$(gh auth token 2>/dev/null || echo '')"
    @echo "✅  Flake updated!"

# Garbage-collect old generations and store paths
[unix]
nix-gc:
    @echo "🧹  Garbage collecting nix..."
    @nh clean all --keep-since 7d --keep 3
    @echo "✅  Garbage collected!"

# ── Private helpers ────────────────────────────────────────────────────────

# Read a value from the dotfiles-secrets input's domains.nix
[private]
_secret-domain key:
    @nix eval --raw --impure --expr '(import "${(builtins.getFlake (toString ./.)).inputs.dotfiles-secrets}/domains.nix").{{ key }}'

# Per-machine build durations, kept local (gitignored). Predictions are
# per-host and read straight from this file; nothing to sync anywhere.
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

stale_days := "7"

[private]
_check-maintenance:
    #!/usr/bin/env bash
    stale_seconds=$(( {{ stale_days }} * 86400 ))
    now=$(date +%s)
    # Freshness comes from the artifact itself: flake-update keeps flake.lock
    # fresh (newest input's lastModified).
    check_task() {
      local label=$1 cmd=$2 last_ts=$3
      if [[ -z "$last_ts" ]]; then
        echo -e "\033[0;33m[WARN]\033[0m $label has never been run; consider: just $cmd"
      elif (( now - last_ts > stale_seconds )); then
        echo -e "\033[0;33m[WARN]\033[0m $label last refreshed $(( (now - last_ts) / 86400 ))d ago; consider: just $cmd"
      fi
    }
    pins_ts=$(jq -r '[.nodes[].locked.lastModified // empty] | max // empty' flake.lock 2>/dev/null || true)
    check_task "Flake inputs" "flake-update" "$pins_ts"
