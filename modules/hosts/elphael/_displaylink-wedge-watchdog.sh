set -euo pipefail

ps_command="${PS_COMMAND:-ps}"
sleep_command="${SLEEP_COMMAND:-sleep}"
systemctl_command="${SYSTEMCTL_COMMAND:-systemctl}"
flip_wait=drm_atomic_helper_wait_for_flip_done

blocked_pids() {
  local pid state wchan

  while read -r pid state wchan; do
    if [[ "$state" == D* && "$wchan" == "$flip_wait" ]]; then
      printf '%s\n' "$pid"
    fi
  done
}

initial_snapshot="$("$ps_command" -eo pid=,state=,wchan:64=)"
mapfile -t initial_pids < <(blocked_pids <<<"$initial_snapshot")
(( ${#initial_pids[@]} > 0 )) || exit 0

printf 'DisplayLink watchdog: DRM flip wait detected in PID(s) %s; confirming for 60 seconds\n' \
  "$(IFS=,; echo "${initial_pids[*]}")"
"$sleep_command" 60

current_snapshot="$("$ps_command" -eo pid=,state=,wchan:64=)"
mapfile -t current_pids < <(blocked_pids <<<"$current_snapshot")
persistent_pid=

for initial_pid in "${initial_pids[@]}"; do
  for current_pid in "${current_pids[@]}"; do
    if [[ "$initial_pid" == "$current_pid" ]]; then
      persistent_pid="$initial_pid"
      break 2
    fi
  done
done

[[ -n "$persistent_pid" ]] || exit 0

if ! "$systemctl_command" is-active --quiet dlm.service; then
  echo 'DisplayLink watchdog: dlm.service is inactive; leaving it stopped'
  exit 0
fi

echo "DisplayLink watchdog: PID $persistent_pid remained blocked for 60 seconds; restarting dlm.service"
"$systemctl_command" restart dlm.service
