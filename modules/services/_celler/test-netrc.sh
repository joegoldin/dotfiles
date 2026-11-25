#!/usr/bin/env bash
set -euo pipefail

migrate() {
  awk -v old=legacy.example -v new=tailnet.example -f "$1"
}

input=$'# machine legacy.example\nmachine legacy.example login ci password synthetic\nmachine old-ci.example login user password other'
expected=$'# machine legacy.example\nmachine tailnet.example login ci password synthetic\nmachine old-ci.example login user password other'
[[ $(migrate "$1" <<< "$input") == "$expected" ]]

input=$'machine\nlegacy.example\nlogin ci\npassword synthetic'
expected=$'machine\ntailnet.example\nlogin ci\npassword synthetic'
[[ $(migrate "$1" <<< "$input") == "$expected" ]]

if migrate "$1" <<< '# machine legacy.example' >/dev/null; then
  echo 'Accepted a netrc with only a commented-out cache entry' >&2
  exit 1
fi
