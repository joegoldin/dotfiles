set -euo pipefail

ps_command="${PS_COMMAND:-ps}"
sleep_command="${SLEEP_COMMAND:-sleep}"
greeter_grace="${GREETER_GRACE_SECONDS:-3}"
max_wait="${MAX_WAIT_SECONDS:-10}"

# KScreenLocker builds one QML view per output when the session locks, and both
# it and this unit are driven by the same logind PrepareForSleep broadcast. When
# the evdi teardown lands inside that init window the views are freed underneath
# PlasmaQuick::QuickViewSharedEngine::rootObject(), the greeter dies, and the
# lock screen is unusable on resume (8 of 12 suspends on the 9.6-day uptime).
# Suspends where the greeter was already up, or had not started at all, were
# unaffected, so wait for it to settle before letting the teardown proceed.
greeter_running() {
  "$ps_command" -eo comm= | grep -q kscreenlocker
}

for (( waited = 0; waited < max_wait; waited++ )); do
  if greeter_running; then
    "$sleep_command" "$greeter_grace"
    exit 0
  fi

  "$sleep_command" 1
done

echo 'DisplayLink suspend: no screen locker greeter appeared; tearing down anyway'
