set -euo pipefail

cgroup="${CGROUP:-/sys/fs/cgroup/user.slice}"
mount_point="${MOUNT_POINT:-/}"
target_usec="${TARGET_USEC:-50000}"
findmnt_command="${FINDMNT_COMMAND:-findmnt}"
lsblk_command="${LSBLK_COMMAND:-lsblk}"

if [[ ! -e "$cgroup/io.latency" ]]; then
  echo "desktop io.latency: io controller not enabled on $cgroup; nothing to do"
  exit 0
fi

# The knob is keyed on the device actually carrying the writes, which for an
# encrypted root is the dm mapper node, not the partition underneath it.
source_device="$("$findmnt_command" -no SOURCE "$mount_point")"
device_number="$("$lsblk_command" -ndo MAJ:MIN "$source_device")"

# Throttles this cgroup's siblings - system.slice, home of nix-gc and the nix
# daemon - once the desktop starts missing the target. It cannot do anything
# about a writer inside user.slice itself, such as a Steam extraction; the
# dirty-byte limits are what bound that case.
printf '%s target=%s\n' "$device_number" "$target_usec" >"$cgroup/io.latency"
echo "desktop io.latency: protecting $cgroup on $device_number at ${target_usec}us"
