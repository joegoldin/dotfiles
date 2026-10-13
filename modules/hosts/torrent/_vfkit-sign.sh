#!/usr/bin/env bash
set -euo pipefail

store=$(cd "$1" && pwd -P)
profile=$2
identity=$3
destination=$4
marker="${destination%.app}.signed-build"

# Keep system codesign/security ahead of Nix's ad-hoc signing tools.
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
if [ ! -r "$profile" ]; then
  echo "vfkit: provisioning profile missing at $profile; activate agenix first" >&2
  exit 1
fi
profile_hash=$(shasum -a 256 "$profile" | cut -d ' ' -f1)
stamp="$store $profile_hash $identity"
if [ -d "$destination" ] && [ -f "$marker" ] &&
   [ "$(cat "$marker")" = "$stamp" ] &&
   codesign --verify --strict "$destination" 2>/dev/null; then
  exit 0
fi

mkdir -p "$(dirname "$destination")"
staging=$(mktemp -d "$(dirname "$destination")/.vfkit-sign.XXXXXX")
installed=false
committed=false
cleanup() {
  if [ "$committed" = false ]; then
    if [ "$installed" = true ]; then
      rm -rf "$destination"
    fi
    if [ -e "$staging/previous.app" ]; then
      mv "$staging/previous.app" "$destination"
    fi
    if [ -f "$staging/previous-marker" ]; then
      mv "$staging/previous-marker" "$marker"
    fi
  fi
  rm -rf "$staging"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

cp -R "$store/Applications/vfkit.app" "$staging/vfkit.app"
chmod -R u+w "$staging/vfkit.app"
if ! (cd "$store/share/vfkit" && sh contrib/usb/sign.sh "$staging/vfkit.app" "$identity" "$profile"); then
  echo "vfkit: signing failed; unlock the login keychain and rerun activation in a Mac terminal to approve key access" >&2
  exit 1
fi
# A valid signature alone does not prove that macOS accepts the embedded
# profile for this machine and restricted entitlement.
"$staging/vfkit.app/Contents/MacOS/vfkit" --help >/dev/null
printf '%s\n' "$stamp" > "$staging/new-marker"
if [ -f "$marker" ]; then
  mv "$marker" "$staging/previous-marker"
fi
if [ -e "$destination" ]; then
  mv "$destination" "$staging/previous.app"
fi
mv "$staging/vfkit.app" "$destination"
installed=true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$destination"
mv "$staging/new-marker" "$marker"
committed=true
