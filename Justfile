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
      host=farum-azula
    else
      # Match old + new hostnames so the first switch (before a box adopts its
      # renamed hostName) still builds the right config.
      case "$(hostname)" in
        malenia | joe-steamdeck)        host=malenia ;;
        volcano-manor | office-pc)      host=volcano-manor ;;
        rennala | racknerd-cloud-agent) host=rennala ;;
        dectus | cloud-proxy)           host=dectus ;;
        *)                              host=elphael ;; # elphael / joe-desktop
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

# Rebuild dectus in place (build locally, deploy over ssh)
[unix]
build-to-dectus:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on dectus VPS (build locally, deploy remote)..."
    SSH_DOMAIN=$(just _secret-domain dectusSshDomain)
    SSH_USER=$(just _secret-domain sshUser)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nixos-rebuild switch --flake .#dectus --target-host "$SSH_USER@$SSH_DOMAIN" --build-host localhost --sudo --accept-flake-config --log-format internal-json -v |& nom --json
    echo "✅  Rebuilt dectus VPS!"

# Rebuild rennala in place (build locally, deploy over ssh)
[unix]
build-to-rennala:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on rennala VPS (build locally, deploy remote)..."
    SSH_DOMAIN=$(just _secret-domain rennalaSshDomain)
    SSH_USER=$(just _secret-domain sshUser)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nixos-rebuild switch --flake .#rennala --target-host "$SSH_USER@$SSH_DOMAIN" --build-host localhost --sudo --accept-flake-config --fallback --log-format internal-json -v |& nom --json
    echo "✅  Rebuilt rennala VPS!"

# Rebuild farum-azula in place. It's aarch64 (Oracle ARM), so build ON the box
# (--build-host = target); cross-building locally on x86_64 goes through QEMU
# emulation, which segfaults on large C builds (e.g. openldap). Eval is still local
# (arch-independent); only the realisation happens on the ARM box.
[unix]
build-to-farum-azula:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on farum-azula (aarch64 — builds on the box)..."
    FARUM_AZULA_DOMAIN=$(just _secret-domain farumAzulaDomain)
    SSH_USER=$(just _secret-domain sshUser)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nixos-rebuild switch --flake .#farum-azula \
      --target-host "$SSH_USER@$FARUM_AZULA_DOMAIN" \
      --build-host "$SSH_USER@$FARUM_AZULA_DOMAIN" \
      --sudo --accept-flake-config
    echo "✅  Rebuilt farum-azula!"

# Rebuild erdtree (beefy dedicated gaming/HPC box) in place (pass --local to build here)
[unix]
build-to-erdtree local="":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on erdtree 🌳..."
    ERDTREE_DOMAIN=$(just _secret-domain erdtreeSshDomain)
    SSH_USER=$(just _secret-domain sshUser)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    BUILD_HOST_ARGS=()
    if [ "{{ local }}" = "--local" ]; then
      BUILD_HOST_ARGS=(--build-host localhost)
    fi
    nixos-rebuild switch --flake .#erdtree --target-host "$SSH_USER@$ERDTREE_DOMAIN" "${BUILD_HOST_ARGS[@]}" --sudo --accept-flake-config
    echo "✅  Rebuilt erdtree!"

# Rebuild siofra (misc-cloud VPS) in place (pass --local to build here)
[unix]
build-to-siofra local="":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on siofra 🌊..."
    SIOFRA_DOMAIN=$(just _secret-domain siofraSshDomain)
    SSH_USER=$(just _secret-domain sshUser)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    BUILD_HOST_ARGS=()
    if [ "{{ local }}" = "--local" ]; then
      BUILD_HOST_ARGS=(--build-host localhost)
    fi
    nixos-rebuild switch --flake .#siofra --target-host "$SSH_USER@$SIOFRA_DOMAIN" "${BUILD_HOST_ARGS[@]}" --sudo --accept-flake-config
    echo "✅  Rebuilt siofra!"

# Rebuild melina (home-automation box) in place over ssh (defaults to its LAN IP)
[unix]
build-to-melina host="192.168.0.236":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on melina 🏡..."
    SSH_USER=$(just _secret-domain sshUser)
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    nixos-rebuild switch --flake .#melina --target-host "$SSH_USER@{{ host }}" --sudo --accept-flake-config
    echo "✅  Rebuilt melina!"

# Rebuild the scarab (Pi) in place over ssh, updating its active config, via nh.
# Builds locally — aarch64 offloads to the virby linux builder — then copies the
# closure to the Pi and switches. Deploys as the `joe` user (root ssh login is
# disabled); joe has passwordless sudo, hence --elevation-strategy passwordless.
# Pass an IP if scarab.local won't resolve (e.g. just build-to-scarab
# 192.168.0.18). --fallback + http2=false dodge the attic cache's flaky
# NARs/HTTP2 the way build-scarab-image does.
[unix]
build-to-scarab host="scarab.local" user="joe":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔨  Rebuilding NixOS on the scarab 🕷️  (build local → deploy {{ user }}@{{ host }})..."
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')
    http2 = false"
    nh os switch . -H scarab --target-host "{{ user }}@{{ host }}" --elevation-strategy passwordless --accept-flake-config --fallback
    echo "✅  Rebuilt scarab! (reboot if a new kernel/overlay landed)"

# ── Bootstrap (first deploy onto a fresh machine) ─────────────────────────

# Install NixOS onto a fresh rennala VPS via nixos-anywhere
[unix]
deploy-rennala IP:
    @echo "🚀  Deploying Nix config to rennala VPS..."
    , nixos-anywhere --flake .#rennala --build-on local joe@{{ IP }}
    @echo "✅  Deployed to rennala VPS!"

# Install NixOS onto a fresh dectus VPS via nixos-anywhere
[unix]
deploy-dectus IP USER="ubuntu":
    @echo "🚀  Deploying Nix config to dectus VPS..."
    , nixos-anywhere --flake .#dectus --build-on local {{ USER }}@{{ IP }}
    @echo "✅  Deployed to dectus VPS!"

# Encrypted first-install via nixos-anywhere: generates ONE SSH host key shared
# by the booted system and the initrd (seeded into both via --extra-files, so
# unlocking on :22 doesn't churn known_hosts — and it doubles as the agenix
# identity, printed for keys.nix), prompts twice for the LUKS passphrase
# (--disk-encryption-keys), and captures real hardware (--generate-hardware-config;
# commit it after). Fresh box logs in as root; pass USER=ubuntu (etc.) if the
# image differs. After first boot the box halts in the initrd — unlock with
# `ssh root@<host>` (your joe key) and enter the passphrase.
#
# erdtree is a Dell w/ a Broadcom BCM57800 NIC: the stock nixos-anywhere kexec
# image lacks bnx2x firmware, so the installer boots but never gets network
# (deploy hangs polling :22). We build our own kexec image (26.05 + all
# redistributable firmware + bnx2x/megaraid_sas) and pass it via --kexec.
[unix]
deploy-erdtree IP USER="root":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🚀  Deploying encrypted NixOS to erdtree 🌳 ..."
    TMP=$(mktemp -d); trap "rm -rf \"$TMP\"" EXIT
    install -d "$TMP/extra/etc/ssh"; install -d -m 700 "$TMP/extra/etc/secrets/initrd"
    # One host key for the booted system + the initrd (so :22 is seamless).
    ssh-keygen -t ed25519 -N "" -C erdtree -f "$TMP/extra/etc/ssh/ssh_host_ed25519_key" >/dev/null
    cp "$TMP/extra/etc/ssh/ssh_host_ed25519_key" "$TMP/extra/etc/secrets/initrd/ssh_host_ed25519_key"
    chmod 600 "$TMP/extra/etc/ssh/ssh_host_ed25519_key" "$TMP/extra/etc/secrets/initrd/ssh_host_ed25519_key"
    echo "🔑  erdtree host key (add to keys.nix as erdtree, then rekey):"; cat "$TMP/extra/etc/ssh/ssh_host_ed25519_key.pub"
    export NIX_CONFIG="access-tokens = github.com=$(gh auth token 2>/dev/null || echo '')"
    echo "🧩  Building custom kexec image (bnx2x + megaraid_sas + firmware)..."
    KEXEC_OUT=$(nix build --no-link --print-out-paths --impure --accept-flake-config --expr '
      let
        flake = builtins.getFlake (toString ./.);
        images = builtins.getFlake "github:nix-community/nixos-images";
        nixpkgs = flake.inputs.nixpkgs;
        lib = nixpkgs.lib;
        system = "x86_64-linux";
      in (nixpkgs.legacyPackages.${system}.nixos [
        images.nixosModules.kexec-installer
        images.nixosModules.noninteractive
        # The installer modules force enableRedistributableFirmware OFF (small
        # image), so a plain `true` loses — mkForce it back on. firmwareCompression
        # = "none" ships the blobs UNCOMPRESSED (bnx2x-e2-*.fw), so the kernel does
        # not depend on fw-loader xz/zstd support to load the BCM57800 firmware.
        { hardware.enableRedistributableFirmware = lib.mkForce true;
          hardware.firmwareCompression = lib.mkForce "none";
          boot.initrd.availableKernelModules = [ "bnx2x" "megaraid_sas" ];
          boot.kernelModules = [ "bnx2x" ]; }
      ]).config.system.build.kexecInstallerTarball')
    KEXEC_TAR=$(echo "$KEXEC_OUT"/*.tar.gz)
    echo "🧩  kexec image: $KEXEC_TAR"
    while :; do
      read -rsp "LUKS passphrase for erdtree: " PASS; echo
      read -rsp "Confirm passphrase: " PASS2; echo
      if [ -z "$PASS" ]; then echo "  ✗ empty passphrase — try again"; continue; fi
      if [ "$PASS" = "$PASS2" ]; then break; fi
      echo "  ✗ passphrases did not match — try again"
    done
    printf %s "$PASS" > "$TMP/luks.key"; chmod 600 "$TMP/luks.key"
    , nixos-anywhere \
      --kexec "$KEXEC_TAR" \
      --generate-hardware-config nixos-generate-config ./modules/hosts/erdtree/_hardware-configuration.nix \
      --disk-encryption-keys /tmp/luks.key "$TMP/luks.key" \
      --extra-files "$TMP/extra" \
      --flake .#erdtree --build-on local {{ USER }}@{{ IP }}
    echo "✅  Deployed erdtree! Unlock on boot: ssh root@erdtree.turnin.quest"

# Encrypted first-install for siofra (see deploy-erdtree for details).
[unix]
deploy-siofra IP USER="root":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🚀  Deploying encrypted NixOS to siofra 🌊 ..."
    TMP=$(mktemp -d); trap "rm -rf \"$TMP\"" EXIT
    install -d "$TMP/extra/etc/ssh"; install -d -m 700 "$TMP/extra/etc/secrets/initrd"
    # One host key for the booted system + the initrd (so :22 is seamless).
    ssh-keygen -t ed25519 -N "" -C siofra -f "$TMP/extra/etc/ssh/ssh_host_ed25519_key" >/dev/null
    cp "$TMP/extra/etc/ssh/ssh_host_ed25519_key" "$TMP/extra/etc/secrets/initrd/ssh_host_ed25519_key"
    chmod 600 "$TMP/extra/etc/ssh/ssh_host_ed25519_key" "$TMP/extra/etc/secrets/initrd/ssh_host_ed25519_key"
    echo "🔑  siofra host key (add to keys.nix as siofra, then rekey):"; cat "$TMP/extra/etc/ssh/ssh_host_ed25519_key.pub"
    while :; do
      read -rsp "LUKS passphrase for siofra: " PASS; echo
      read -rsp "Confirm passphrase: " PASS2; echo
      if [ -z "$PASS" ]; then echo "  ✗ empty passphrase — try again"; continue; fi
      if [ "$PASS" = "$PASS2" ]; then break; fi
      echo "  ✗ passphrases did not match — try again"
    done
    printf %s "$PASS" > "$TMP/luks.key"; chmod 600 "$TMP/luks.key"
    , nixos-anywhere \
      --generate-hardware-config nixos-generate-config ./modules/hosts/siofra/_hardware-configuration.nix \
      --disk-encryption-keys /tmp/luks.key "$TMP/luks.key" \
      --extra-files "$TMP/extra" \
      --flake .#siofra --build-on local {{ USER }}@{{ IP }}
    echo "✅  Deployed siofra! Unlock on boot: ssh root@siofra.turnin.quest"

# Encrypted first-install of the mini-PC (melina) via nixos-anywhere: generates
# ONE shared SSH host key (booted system + initrd, so :22 unlock doesn't churn
# known_hosts), prompts twice for the LUKS passphrase, captures real hardware.
# Back up + VERIFY the Home Assistant data OFF-box first — this WIPES
# /dev/nvme0n1. After first boot the box halts in the initrd — unlock with
# `ssh root@192.168.0.236` (LAN) and enter the passphrase.
[unix]
deploy-melina IP USER="root":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🚀  Deploying encrypted NixOS to melina 🏡 ..."
    TMP=$(mktemp -d); trap "rm -rf \"$TMP\"" EXIT
    install -d "$TMP/extra/etc/ssh"; install -d -m 700 "$TMP/extra/etc/secrets/initrd"
    ssh-keygen -t ed25519 -N "" -C melina -f "$TMP/extra/etc/ssh/ssh_host_ed25519_key" >/dev/null
    cp "$TMP/extra/etc/ssh/ssh_host_ed25519_key" "$TMP/extra/etc/secrets/initrd/ssh_host_ed25519_key"
    chmod 600 "$TMP/extra/etc/ssh/ssh_host_ed25519_key" "$TMP/extra/etc/secrets/initrd/ssh_host_ed25519_key"
    echo "🔑  melina host key:"; cat "$TMP/extra/etc/ssh/ssh_host_ed25519_key.pub"
    while :; do
      read -rsp "LUKS passphrase for melina: " PASS; echo
      read -rsp "Confirm passphrase: " PASS2; echo
      if [ -z "$PASS" ]; then echo "  ✗ empty passphrase — try again"; continue; fi
      if [ "$PASS" = "$PASS2" ]; then break; fi
      echo "  ✗ passphrases did not match — try again"
    done
    printf %s "$PASS" > "$TMP/luks.key"; chmod 600 "$TMP/luks.key"
    , nixos-anywhere \
      --generate-hardware-config nixos-generate-config ./modules/hosts/melina/_hardware-configuration.nix \
      --disk-encryption-keys /tmp/luks.key "$TMP/luks.key" \
      --extra-files "$TMP/extra" \
      --flake .#melina --build-on local {{ USER }}@{{ IP }}
    echo "✅  Deployed melina! Unlock on boot: ssh root@192.168.0.236 (LAN), then restore Home Assistant data + just build-to-melina"

# Encrypted first-install for farum-azula — Oracle Cloud Ampere ARM64 (aarch64),
# fresh Ubuntu. Same flow as deploy-siofra/melina (LUKS root + initrd-SSH unlock,
# one host key seeded into both), but builds on the ARM target (--build-on remote)
# to avoid local aarch64 emulation, and connects as the Ubuntu default user. The
# printed host key is NEW — replace the farum-azula entry in keys.nix with it,
# rekey, push, then `just build-to-farum-azula`.
[unix]
deploy-farum-azula IP USER="ubuntu":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🚀  Deploying encrypted NixOS to farum-azula (Oracle ARM64) 🌩️ ..."
    TMP=$(mktemp -d); trap "rm -rf \"$TMP\"" EXIT
    install -d "$TMP/extra/etc/ssh"; install -d -m 700 "$TMP/extra/etc/secrets/initrd"
    ssh-keygen -t ed25519 -N "" -C farum-azula -f "$TMP/extra/etc/ssh/ssh_host_ed25519_key" >/dev/null
    cp "$TMP/extra/etc/ssh/ssh_host_ed25519_key" "$TMP/extra/etc/secrets/initrd/ssh_host_ed25519_key"
    chmod 600 "$TMP/extra/etc/ssh/ssh_host_ed25519_key" "$TMP/extra/etc/secrets/initrd/ssh_host_ed25519_key"
    echo "🔑  farum-azula host key (REPLACE the farum-azula entry in keys.nix, then rekey):"; cat "$TMP/extra/etc/ssh/ssh_host_ed25519_key.pub"
    while :; do
      read -rsp "LUKS passphrase for farum-azula: " PASS; echo
      read -rsp "Confirm passphrase: " PASS2; echo
      if [ -z "$PASS" ]; then echo "  ✗ empty passphrase — try again"; continue; fi
      if [ "$PASS" = "$PASS2" ]; then break; fi
      echo "  ✗ passphrases did not match — try again"
    done
    printf %s "$PASS" > "$TMP/luks.key"; chmod 600 "$TMP/luks.key"
    # --build-on remote builds the closure on the ARM installer, substituting from
    # our attic + numtide caches — pass their signing keys so it trusts those
    # signatures (read from the flake so no secrets land in this public Justfile).
    EXTRA_SUBS=$(nix eval --raw .#nixosConfigurations.farum-azula.config.nix.settings.extra-substituters --apply 'builtins.concatStringsSep " "')
    EXTRA_KEYS=$(nix eval --raw .#nixosConfigurations.farum-azula.config.nix.settings.extra-trusted-public-keys --apply 'builtins.concatStringsSep " "')
    , nixos-anywhere \
      --generate-hardware-config nixos-generate-config ./modules/hosts/farum-azula/_hardware-configuration.nix \
      --disk-encryption-keys /tmp/luks.key "$TMP/luks.key" \
      --extra-files "$TMP/extra" \
      --option extra-substituters "$EXTRA_SUBS" \
      --option extra-trusted-public-keys "$EXTRA_KEYS" \
      --flake .#farum-azula --build-on remote {{ USER }}@{{ IP }}
    echo "✅  Deployed farum-azula! Unlock on boot: ssh root@farum-azula.turnin.quest, then replace the key in keys.nix, rekey, push, just build-to-farum-azula."

# First darwin activation on a fresh mac (before nh exists)
[macos]
build-macos-initial:
    @echo "🔨  Building Nix config for macOS 🍎 (initial)..."
    sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake .#torrent
    @echo "✅  Built for macOS!"

# ── Installer ISO (volcano-manor) ──────────────────────────────────────────────

# Build the offline installer ISO with the full volcano-manor closure baked in
[unix]
build-volcano-manor-iso:
    @echo "Building volcano-manor installer ISO (includes full system closure)..."
    @nix build .#nixosConfigurations.volcano-manor-installer.config.system.build.isoImage --log-format internal-json -v |& nom --json
    echo "ISO built: $(ls result/iso/*.iso)"

# Write the built ISO to a USB device (defaults to /dev/sdb)
[confirm("This will ERASE the target device. Continue?")]
[unix]
write-iso device="":
    #!/usr/bin/env bash
    set -euo pipefail
    ISO=$(ls result/iso/*.iso 2>/dev/null | head -1)
    if [ -z "$ISO" ]; then
      echo "No ISO found. Run 'just build-volcano-manor-iso' first."
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

# ── Raspberry Pi SD image (scarab) ────────────────────────────────────────

# Cross-builds aarch64 via binfmt on x86_64; builds natively on aarch64.
# --accept-flake-config trusts the nixos-raspberrypi cachix substituter.
# --fallback builds from source when a substituter serves a corrupt/partial NAR
# (e.g. the attic cache occasionally truncates firmware/zfs-user NARs).
# Build the scarab SD-card image (uncompressed .img)
[unix]
build-scarab-image:
    @echo "🔨  Building scarab SD image (aarch64; builds the rpi kernel if not cached)..."
    @nix build .#nixosConfigurations.scarab.config.system.build.sdImage --accept-flake-config --fallback --log-format internal-json -v |& nom --json
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
# Usage: just bake-scarab-image [out.img] [img=/path/to/raw.img] [item=] [vault=] [key=]
[unix]
bake-scarab-image out="scarab-sd.img" img="" item="Crawler RasPi Nixos SSH Key" vault="Private" key="":
    #!/usr/bin/env bash
    set -euo pipefail
    IMG="{{ img }}"
    if [ -z "$IMG" ]; then
      IMG=$(ls result/sd-image/*.img 2>/dev/null | head -1)
    fi
    if [ -z "$IMG" ] || [ ! -f "$IMG" ]; then
      echo "No image found. Pass img=/path/to/raw.img, or run 'just build-scarab-image' first."
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
    # DEBUGFS_PAGER=cat stops debugfs piping output through a pager (no q prompt).
    export DEBUGFS_PAGER=cat
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
    EOF
    # Run the injection quietly; keep the log only to show it if something fails.
    LOG=$(mktemp)
    "${DEBUGFS[@]}" -w -f "$DBG" "$OUT?offset=$OFF" >"$LOG" 2>&1 || true
    rm -f "$DBG"

    # Confirm by reading the pubkey back out of the image and matching the source.
    want=$(awk '{print $2}' "$PUB")
    got=$("${DEBUGFS[@]}" -R "cat /etc/ssh/ssh_host_ed25519_key.pub" "$OUT?offset=$OFF" 2>/dev/null | awk '{print $2}')
    if [ -z "$want" ] || [ "$want" != "$got" ]; then
      echo "❌  Host key injection failed. debugfs output:"
      cat "$LOG"; rm -f "$LOG"
      exit 1
    fi
    rm -f "$LOG"

    SIZE=$(du -h "$OUT" | cut -f1)
    echo "✅  Ready: $OUT (${SIZE}) — host key injected & verified."
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
