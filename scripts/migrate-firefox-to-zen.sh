#!/usr/bin/env bash
# One-time migration of Firefox profile data into the Zen profile.
# Reuses the declarative home-manager config; copies only dynamic user data.
# Guide: https://docs.zen-browser.app/guides/manage-profiles
set -euo pipefail

FF_ROOT="${HOME}/.mozilla/firefox"
ZEN_PROFILE="${HOME}/.zen/Default"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# 1. Refuse to run while either browser is alive (avoids DB corruption).
if pgrep -x firefox >/dev/null 2>&1 || pgrep -x .firefox-wrappe >/dev/null 2>&1; then
  die "Firefox is running. Close it completely first."
fi
if pgrep -x zen >/dev/null 2>&1 || pgrep -x .zen-wrapped >/dev/null 2>&1 || pgrep -x zen-bin >/dev/null 2>&1; then
  die "Zen is running. Close it completely first."
fi

# 2. Locate the source Firefox profile (Default from profiles.ini, else newest).
[ -d "$FF_ROOT" ] || die "No Firefox profile root at $FF_ROOT"
SRC=""
if [ -f "$FF_ROOT/profiles.ini" ]; then
  # Prefer the [Install...] Default=, else fall back to newest *.default* dir.
  rel="$(awk -F= '/^\[Install/{i=1} i&&/^Default=/{print $2; exit}' "$FF_ROOT/profiles.ini")"
  [ -n "${rel:-}" ] && [ -d "$FF_ROOT/$rel" ] && SRC="$FF_ROOT/$rel"
fi
if [ -z "$SRC" ]; then
  SRC="$(find "$FF_ROOT" -maxdepth 1 -type d -name '*.default*' -printf '%T@ %p\n' \
        | sort -rn | head -1 | cut -d' ' -f2-)"
fi
[ -n "$SRC" ] && [ -d "$SRC" ] || die "Could not find a Firefox source profile under $FF_ROOT"

# 3. Zen profile dir must exist (created by home-manager activation / first run).
[ -d "$ZEN_PROFILE" ] || die "Zen profile $ZEN_PROFILE not found. Rebuild and launch Zen once, then re-run."

printf 'Source Firefox profile: %s\n' "$SRC"
printf 'Target Zen profile:     %s\n' "$ZEN_PROFILE"

# 4. Backup the target, then copy. compatibility.ini and extensions* are
#    intentionally omitted (add-ons are force-installed declaratively).
ts="$(date +%Y%m%d-%H%M%S)"
backup="${ZEN_PROFILE}.bak-${ts}"
cp -a "$ZEN_PROFILE" "$backup"
printf 'Backed up existing Zen profile to %s\n' "$backup"

items=(
  places.sqlite          # bookmarks + history
  favicons.sqlite
  cookies.sqlite         # login sessions
  cert9.db               # \
  key4.db                #  > saved passwords (also used by some integrations)
  logins.json            # /
  permissions.sqlite
  formhistory.sqlite
  sessionCheckpoints.json
  sessionstore.jsonlz4   # \ open tabs / windows
  sessionstore-backups   # /
  search.json.mozlz4     # search engines
  prefs.js               # about:config
  storage                # add-on local storage (best-effort)
)

for item in "${items[@]}"; do
  if [ -e "$SRC/$item" ]; then
    rm -rf "${ZEN_PROFILE:?}/$item"
    cp -a "$SRC/$item" "$ZEN_PROFILE/$item"
    printf '  copied %s\n' "$item"
  fi
done

printf '\nDone. Notes:\n'
printf '  - Search engines and many about:config keys are enforced by Nix policy/user.js and win over copied prefs.js.\n'
printf '  - Add-ons are force-installed declaratively; their logins/local-storage are not fully migrated (re-auth 1Password via the desktop app).\n'
printf '  - If Zen shows an incompatibility error on first launch, remove %s/compatibility.ini and relaunch.\n' "$ZEN_PROFILE"
