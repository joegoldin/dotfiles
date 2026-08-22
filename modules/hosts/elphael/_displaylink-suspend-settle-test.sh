#!/usr/bin/env bash
set -euo pipefail

settle="$(dirname "$0")/_displaylink-suspend-settle.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() {
  if [[ -n "${case_dir:-}" && -f "$case_dir/output" ]]; then
    cat "$case_dir/output" >&2
  fi
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$tmp/ps" <<'EOF'
#!/bin/sh
set -eu
count_file="$TEST_STATE/ps-count"
count=0
if [ -f "$count_file" ]; then
  read -r count <"$count_file"
fi
count=$((count + 1))
printf '%s\n' "$count" >"$count_file"
if [ -f "$TEST_STATE/ps-$count" ]; then
  cat "$TEST_STATE/ps-$count"
else
  cat "$TEST_STATE/ps-default"
fi
EOF

cat >"$tmp/sleep" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$TEST_STATE/sleep-calls"
EOF

chmod +x "$tmp/ps" "$tmp/sleep"

run_settle() {
  local case_dir=$1

  TEST_STATE="$case_dir" \
    GREETER_GRACE_SECONDS=3 \
    MAX_WAIT_SECONDS=5 \
    PS_COMMAND="$tmp/ps" \
    SLEEP_COMMAND="$tmp/sleep" \
    bash "$settle" >"$case_dir/output" 2>&1
}

greeter_present() { printf '%s\n' 'kwin_wayland' '.kscreenlocker_' 'plasmashell'; }
greeter_absent() { printf '%s\n' 'kwin_wayland' 'plasmashell'; }

# The greeter is already building its per-output views, so hold off the evdi
# teardown for the grace period rather than tearing down on top of it.
case_dir="$tmp/greeter-already-up"
mkdir "$case_dir"
greeter_present >"$case_dir/ps-default"
run_settle "$case_dir"
[[ "$(cat "$case_dir/ps-count")" == 1 ]] ||
  fail 'greeter-already-up case kept polling after finding the greeter'
[[ "$(cat "$case_dir/sleep-calls")" == 3 ]] ||
  fail 'greeter-already-up case did not wait exactly one grace period'

# The greeter can lose the race to start; keep polling until it shows up.
case_dir="$tmp/greeter-appears-late"
mkdir "$case_dir"
greeter_absent >"$case_dir/ps-1"
greeter_absent >"$case_dir/ps-2"
greeter_present >"$case_dir/ps-default"
run_settle "$case_dir"
[[ "$(cat "$case_dir/ps-count")" == 3 ]] ||
  fail 'greeter-appears-late case did not poll until the greeter appeared'
[[ "$(cat "$case_dir/sleep-calls")" == "$(printf '1\n1\n3')" ]] ||
  fail 'greeter-appears-late case did not poll then wait out the grace period'

# Locking may be disabled entirely: never block suspend indefinitely.
case_dir="$tmp/greeter-never-appears"
mkdir "$case_dir"
greeter_absent >"$case_dir/ps-default"
run_settle "$case_dir"
[[ "$(cat "$case_dir/ps-count")" == 5 ]] ||
  fail 'greeter-never-appears case did not stop polling at the wait cap'
[[ "$(cat "$case_dir/sleep-calls")" == "$(printf '1\n1\n1\n1\n1')" ]] ||
  fail 'greeter-never-appears case waited past the cap'

printf '%s\n' 'PASS: DisplayLink suspend settle behavior'
