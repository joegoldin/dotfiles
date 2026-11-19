#!/usr/bin/env bash
set -euo pipefail

script="$(dirname "$0")/_desktop-io-latency.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() {
  if [[ -n "${case_dir:-}" && -f "$case_dir/output" ]]; then
    cat "$case_dir/output" >&2
  fi
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$tmp/findmnt" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$TEST_STATE/findmnt-calls"
cat "$TEST_STATE/findmnt-out"
EOF

cat >"$tmp/lsblk" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$TEST_STATE/lsblk-calls"
cat "$TEST_STATE/lsblk-out"
EOF

chmod +x "$tmp/findmnt" "$tmp/lsblk"

run_script() {
  local case_dir=$1
  TEST_STATE="$case_dir" \
    CGROUP="$case_dir/cgroup" \
    MOUNT_POINT=/ \
    TARGET_USEC=50000 \
    FINDMNT_COMMAND="$tmp/findmnt" \
    LSBLK_COMMAND="$tmp/lsblk" \
    bash "$script" >"$case_dir/output" 2>&1
}

# io.latency wants the major:minor of the device backing the mount, which for an
# encrypted root is the dm mapper node rather than the underlying partition.
case_dir="$tmp/luks-root"
mkdir -p "$case_dir/cgroup"
: >"$case_dir/cgroup/io.latency"
printf '%s\n' '/dev/mapper/luks-bf7e5885-6a8e-447b-bb6d-b682b2991325' >"$case_dir/findmnt-out"
printf '%s\n' '254:0' >"$case_dir/lsblk-out"
run_script "$case_dir"
[[ "$(cat "$case_dir/cgroup/io.latency")" == '254:0 target=50000' ]] ||
  fail "wrote unexpected io.latency: $(cat "$case_dir/cgroup/io.latency")"
grep -q -- '-no SOURCE /' "$case_dir/findmnt-calls" ||
  fail 'did not resolve the device backing the mount point'
grep -q -- 'MAJ:MIN /dev/mapper/luks-bf7e5885-6a8e-447b-bb6d-b682b2991325' "$case_dir/lsblk-calls" ||
  fail 'did not look up the major:minor of the resolved device'

# A missing io.latency file means the io controller is not enabled on the slice;
# that must not fail the boot.
case_dir="$tmp/no-io-controller"
mkdir -p "$case_dir/cgroup"
printf '%s\n' '/dev/mapper/root' >"$case_dir/findmnt-out"
printf '%s\n' '254:0' >"$case_dir/lsblk-out"
run_script "$case_dir" || fail 'missing io.latency should not be fatal'
grep -qi 'io controller' "$case_dir/output" ||
  fail 'missing io.latency was not reported'

printf '%s\n' 'PASS: desktop io.latency behavior'
