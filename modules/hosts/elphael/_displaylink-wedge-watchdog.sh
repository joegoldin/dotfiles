set -euo pipefail

journal_command="${JOURNAL_COMMAND:-journalctl}"
sleep_command="${SLEEP_COMMAND:-sleep}"
systemctl_command="${SYSTEMCTL_COMMAND:-systemctl}"
window_seconds="${WINDOW_SECONDS:-15}"
confirm_seconds="${CONFIRM_SECONDS:-15}"
min_timeouts="${MIN_TIMEOUTS:-5}"
flip_message='Pageflip timed out'

# Detect the freeze the way KWin reports it, not by looking for a blocked task.
# When the evdi output is DPMS'd off the driver stops completing page flips and
# KWin spins on a timeout once per second - it stays runnable throughout, so the
# old scan for a task in D state on drm_atomic_helper_wait_for_flip_done ran 24
# times during a 338s freeze and matched nothing.
timeouts_in_window() {
  "$journal_command" --since "-${window_seconds}s" --no-pager --output=cat 2>/dev/null |
    grep -c "$flip_message" || true
}

initial=$(timeouts_in_window)
(( initial >= min_timeouts )) || exit 0

printf 'DisplayLink watchdog: %s KWin pageflip timeouts in %ss; confirming for %ss\n' \
  "$initial" "$window_seconds" "$confirm_seconds"
"$sleep_command" "$confirm_seconds"

current=$(timeouts_in_window)
if (( current < min_timeouts )); then
  echo 'DisplayLink watchdog: pageflip timeouts stopped on their own; leaving DisplayLink alone'
  exit 0
fi

if ! "$systemctl_command" is-active --quiet dlm.service; then
  echo 'DisplayLink watchdog: dlm.service is inactive; leaving it stopped'
  exit 0
fi

echo "DisplayLink watchdog: pageflip timeouts persisted past ${confirm_seconds}s; restarting dlm.service"
"$systemctl_command" restart dlm.service
