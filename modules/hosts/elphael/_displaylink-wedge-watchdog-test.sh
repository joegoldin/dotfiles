#!/usr/bin/env bash
set -euo pipefail

watchdog="$(dirname "$0")/_displaylink-wedge-watchdog.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() {
  if [[ -n "${case_dir:-}" && -f "$case_dir/output" ]]; then
    cat "$case_dir/output" >&2
  fi
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$tmp/journalctl" <<'EOF'
#!/bin/sh
set -eu
count_file="$TEST_STATE/journal-count"
count=0
if [ -f "$count_file" ]; then
  read -r count <"$count_file"
fi
count=$((count + 1))
printf '%s\n' "$count" >"$count_file"
if [ -f "$TEST_STATE/journal-$count" ]; then
  cat "$TEST_STATE/journal-$count"
else
  cat "$TEST_STATE/journal-default"
fi
EOF

cat >"$tmp/sleep" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$TEST_STATE/sleep-calls"
EOF

cat >"$tmp/systemctl" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$TEST_STATE/systemctl-calls"
case "$1" in
  is-active) exit "${SYSTEMCTL_IS_ACTIVE_STATUS:-0}" ;;
  restart) exit "${SYSTEMCTL_RESTART_STATUS:-0}" ;;
esac
EOF

chmod +x "$tmp/journalctl" "$tmp/sleep" "$tmp/systemctl"

run_watchdog() {
  local case_dir=$1
  local active_status=${2:-0}
  local restart_status=${3:-0}

  TEST_STATE="$case_dir" \
    SYSTEMCTL_IS_ACTIVE_STATUS="$active_status" \
    SYSTEMCTL_RESTART_STATUS="$restart_status" \
    WINDOW_SECONDS=15 \
    CONFIRM_SECONDS=15 \
    MIN_TIMEOUTS=5 \
    JOURNAL_COMMAND="$tmp/journalctl" \
    SLEEP_COMMAND="$tmp/sleep" \
    SYSTEMCTL_COMMAND="$tmp/systemctl" \
    bash "$watchdog" >"$case_dir/output" 2>&1
}

# KWin logs this once per second for the entire duration of a freeze.
freezing() {
  local n=${1:-10}
  for _ in $(seq 1 "$n"); do
    printf '%s\n' 'Pageflip timed out! This is a bug in the evdi kernel driver'
  done
}

quiet() { printf '%s\n' 'kwin_wayland: nothing interesting here'; }

expect_restart() {
  local case_dir=$1
  printf '%s\n' \
    'is-active --quiet dlm.service' \
    'restart dlm.service' >"$case_dir/expected-systemctl-calls"
  cmp "$case_dir/expected-systemctl-calls" "$case_dir/systemctl-calls"
}

case_dir="$tmp/no-timeouts"
mkdir "$case_dir"
quiet >"$case_dir/journal-default"
run_watchdog "$case_dir"
[[ "$(cat "$case_dir/journal-count")" == 1 ]] ||
  fail 'no-timeouts case did not perform exactly one journal scan'
[[ ! -e "$case_dir/sleep-calls" ]] || fail 'no-timeouts case slept'
[[ ! -e "$case_dir/systemctl-calls" ]] || fail 'no-timeouts case called systemctl'

# A couple of stray timeouts are not a freeze; KWin recovers on its own.
case_dir="$tmp/below-threshold"
mkdir "$case_dir"
freezing 2 >"$case_dir/journal-default"
run_watchdog "$case_dir"
[[ ! -e "$case_dir/systemctl-calls" ]] || fail 'below-threshold case called systemctl'

# The short freezes (11-28s) end by themselves before the confirmation elapses.
case_dir="$tmp/freeze-recovers"
mkdir "$case_dir"
freezing 10 >"$case_dir/journal-1"
quiet >"$case_dir/journal-default"
run_watchdog "$case_dir"
[[ "$(cat "$case_dir/sleep-calls")" == 15 ]] ||
  fail 'freeze-recovers case did not wait one confirmation window'
[[ ! -e "$case_dir/systemctl-calls" ]] || fail 'freeze-recovers case called systemctl'

# The 5.6min and 15.3min freezes: still logging after the confirmation window.
case_dir="$tmp/freeze-persists"
mkdir "$case_dir"
freezing 15 >"$case_dir/journal-default"
run_watchdog "$case_dir"
expect_restart "$case_dir" ||
  fail 'freeze-persists case did not restart DisplayLink'

case_dir="$tmp/dlm-inactive"
mkdir "$case_dir"
freezing 15 >"$case_dir/journal-default"
run_watchdog "$case_dir" 3
[[ "$(cat "$case_dir/systemctl-calls")" == 'is-active --quiet dlm.service' ]] ||
  fail 'dlm-inactive case attempted to start or restart DisplayLink'

case_dir="$tmp/restart-failure"
mkdir "$case_dir"
freezing 15 >"$case_dir/journal-default"
if run_watchdog "$case_dir" 0 1; then
  fail 'restart failure returned success'
fi
grep -q 'restarting dlm.service' "$case_dir/output" ||
  fail 'restart failure was not logged'

printf '%s\n' 'PASS: DisplayLink wedge watchdog behavior'
