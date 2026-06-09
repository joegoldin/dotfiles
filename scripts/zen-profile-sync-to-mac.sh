#!/usr/bin/env bash
# Optional one-time copy of DYNAMIC Zen session state (open/pinned tabs, session)
# from this machine's Zen profile to a destination Zen profile — e.g. rsync'd to
# the Mac. Spaces are declarative (managed-spaces) and bookmarks are declarative
# (secrets/zen/bookmarks.nix), so neither places.sqlite nor Space definitions are
# copied. Run with BOTH browsers closed.
#
# Usage:
#   zen-profile-sync-to-mac.sh <dest-profile-dir>
#   # dest examples:
#   #   local mounted Mac:  /Volumes/.../Library/Application Support/zen/Default
#   #   over ssh (run on Mac, pulling): use the rsync line printed at the end
set -euo pipefail

SRC="${ZEN_SRC:-$HOME/.zen/Default}"
DST="${1:?usage: zen-profile-sync-to-mac.sh <dest-profile-dir>}"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

if pgrep -x zen >/dev/null 2>&1 || pgrep -x .zen-wrapped >/dev/null 2>&1 || pgrep -x zen-bin >/dev/null 2>&1; then
  die "Zen is running. Close it completely on both machines first."
fi
[ -d "$SRC" ] || die "source profile not found: $SRC"
[ -d "$DST" ] || die "dest profile not found: $DST (launch Zen once on the Mac to create it)"

# Dynamic state to carry (sessions, open/pinned tabs). Spaces come from Nix
# (managed-spaces); bookmarks come from Nix (secrets/zen/bookmarks.nix). Add
# 'places.sqlite' here only if you also want history.
items=(
  zen-sessions.jsonlz4
  zen-sessions-backup
  sessionstore.jsonlz4
  sessionstore-backups
  sessionCheckpoints.json
)
for f in "$SRC"/zen-*.json; do
  [ -e "$f" ] && items+=("$(basename "$f")")
done

ts="$(date +%Y%m%d-%H%M%S)"
cp -a "$DST" "${DST}.bak-${ts}"
printf 'Backed up dest to %s.bak-%s\n' "$DST" "$ts"

for item in "${items[@]}"; do
  if [ -e "$SRC/$item" ]; then
    rm -rf "${DST:?}/$item"
    cp -a "$SRC/$item" "$DST/$item"
    printf '  copied %s\n' "$item"
  fi
done

cat <<EOF

Done (local copy). To sync to a Mac over ssh instead, with Zen closed on both:
  rsync -av --backup "\$HOME/.zen/Default/" \\
    'mac.local:Library/Application Support/zen/Default/'
Spaces + bookmarks are managed by Nix, so they re-apply on the next rebuild.
EOF
