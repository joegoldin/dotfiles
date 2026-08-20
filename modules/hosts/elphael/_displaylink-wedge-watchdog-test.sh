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
cat "$TEST_STATE/ps-$count"
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

chmod +x "$tmp/ps" "$tmp/sleep" "$tmp/systemctl"

run_watchdog() {
  local case_dir=$1
  local active_status=${2:-0}
  local restart_status=${3:-0}

  TEST_STATE="$case_dir" \
    SYSTEMCTL_IS_ACTIVE_STATUS="$active_status" \
    SYSTEMCTL_RESTART_STATUS="$restart_status" \
    PS_COMMAND="$tmp/ps" \
    SLEEP_COMMAND="$tmp/sleep" \
    SYSTEMCTL_COMMAND="$tmp/systemctl" \
    bash "$watchdog" >"$case_dir/output" 2>&1
}

matching_worker() {
  printf '%s\n' "${1:-744956} D drm_atomic_helper_wait_for_flip_done"
}

case_dir="$tmp/no-match"
mkdir "$case_dir"
printf '%s\n' '100 S do_wait' >"$case_dir/ps-1"
run_watchdog "$case_dir"
[[ -f "$case_dir/ps-count" && "$(cat "$case_dir/ps-count")" == 1 ]] ||
  fail 'no-match case did not perform exactly one scan'
[[ ! -e "$case_dir/sleep-calls" ]] || fail 'no-match case slept'
[[ ! -e "$case_dir/systemctl-calls" ]] || fail 'no-match case called systemctl'

case_dir="$tmp/transient"
mkdir "$case_dir"
matching_worker >"$case_dir/ps-1"
printf '%s\n' '744956 S worker_thread' >"$case_dir/ps-2"
run_watchdog "$case_dir"
[[ "$(cat "$case_dir/sleep-calls")" == 60 ]] || fail 'transient case did not use 60-second confirmation'
[[ ! -e "$case_dir/systemctl-calls" ]] || fail 'transient case called systemctl'

case_dir="$tmp/different-worker"
mkdir "$case_dir"
matching_worker 744956 >"$case_dir/ps-1"
matching_worker 745100 >"$case_dir/ps-2"
run_watchdog "$case_dir"
[[ ! -e "$case_dir/systemctl-calls" ]] || fail 'different-worker case called systemctl'

case_dir="$tmp/inactive"
mkdir "$case_dir"
matching_worker >"$case_dir/ps-1"
matching_worker >"$case_dir/ps-2"
run_watchdog "$case_dir" 3
[[ "$(cat "$case_dir/systemctl-calls")" == 'is-active --quiet dlm.service' ]] ||
  fail 'inactive case attempted to start or restart DisplayLink'

case_dir="$tmp/persistent"
mkdir "$case_dir"
matching_worker >"$case_dir/ps-1"
matching_worker >"$case_dir/ps-2"
run_watchdog "$case_dir"
printf '%s\n' \
  'is-active --quiet dlm.service' \
  'restart dlm.service' >"$case_dir/expected-systemctl-calls"
cmp "$case_dir/expected-systemctl-calls" "$case_dir/systemctl-calls" ||
  fail 'persistent case did not restart DisplayLink exactly once'

case_dir="$tmp/restart-failure"
mkdir "$case_dir"
matching_worker >"$case_dir/ps-1"
matching_worker >"$case_dir/ps-2"
if run_watchdog "$case_dir" 0 1; then
  fail 'restart failure returned success'
fi

grep -q 'restarting dlm.service' "$case_dir/output" ||
  fail 'restart failure was not logged'

printf '%s\n' 'PASS: DisplayLink wedge watchdog behavior'
