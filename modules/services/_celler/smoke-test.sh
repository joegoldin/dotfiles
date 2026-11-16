#!/usr/bin/env bash
# Exercise the built client/server without fleet credentials or B2 writes.
set -euo pipefail
celler_package=${1:?Pass the Celler store path}
work=$(mktemp -d /tmp/celler-smoke.XXXXXXXX)
umask 077
server_pid=
watcher_pid=
cleanup() {
  if [[ -n "$watcher_pid" ]]; then kill "$watcher_pid" 2>/dev/null || true; wait "$watcher_pid" 2>/dev/null || true; fi
  if [[ -n "$server_pid" ]]; then kill "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true; fi
  rm -rf -- "$work"
}
trap cleanup EXIT
export XDG_CONFIG_HOME="$work/config"
mkdir -p "$XDG_CONFIG_HOME/celler" "$work/storage"
head -c 32 /dev/urandom > "$work/signing-key"
"$celler_package/bin/celler" admin make-token \
  --signing-algorithm hs256 --signing-key "$work/signing-key" \
  --sub smoke-test --validity '1 hour' --create-cache smoke \
  --configure-cache smoke --pull smoke --push smoke > "$work/token"
# A private loopback listener and an isolated SQLite DB/local object directory.
port=37841
cat > "$work/server.toml" <<EOF
listen = "127.0.0.1:$port"
allowed-hosts = ["127.0.0.1:$port"]
api-endpoint = "http://127.0.0.1:$port/"
[database]
url = "sqlite://$work/server.db?mode=rwc"
[storage]
type = "local"
path = "$work/storage"
[jwt]
hs256-secret-key-file = "$work/signing-key"
EOF
cat > "$XDG_CONFIG_HOME/celler/config.toml" <<EOF
default-server = "test"
[servers.test]
endpoint = "http://127.0.0.1:$port/"
token-file = "$work/token"
EOF
"$celler_package/bin/cellerd" -f "$work/server.toml" --mode check-config
"$celler_package/bin/cellerd" -f "$work/server.toml" > "$work/server.log" 2>&1 &
server_pid=$!
ready=false
for _ in {1..100}; do
  kill -0 "$server_pid"
  if curl --silent --output /dev/null "http://127.0.0.1:$port/"; then ready=true; break; fi
  sleep 0.2
done
[[ "$ready" == true ]]
"$celler_package/bin/celler" cache create smoke --public
"$celler_package/bin/celler" cache info smoke 2> "$work/cache-info"
public_key=$(sed -n 's/^[[:space:]]*Public Key: //p' "$work/cache-info")
[[ -n "$public_key" ]]
printf 'Celler push smoke test: %s\n' "$work" > "$work/push-test"
first=$(nix-store --add "$work/push-test")
"$celler_package/bin/celler" push smoke "$first"
nix store verify --store "http://127.0.0.1:$port/smoke" \
  --sigs-needed 1 --trusted-public-keys "$public_key" "$first"
"$celler_package/bin/celler" watch-store --jobs 5 test:smoke > "$work/watch.log" 2>&1 &
watcher_pid=$!
ready=false
for _ in {1..100}; do
  kill -0 "$watcher_pid"
  if grep -q 'Pushing new store paths' "$work/watch.log"; then ready=true; break; fi
  sleep 0.2
done
[[ "$ready" == true ]]
printf 'Celler watcher smoke test: %s\n' "$work" > "$work/watch-test"
second=$(nix-store --add "$work/watch-test")
ready=false
for _ in {1..100}; do
  kill -0 "$watcher_pid"
  if nix path-info --store "http://127.0.0.1:$port/smoke" \
    --option narinfo-cache-negative-ttl 0 "$second" > /dev/null 2>&1; then ready=true; break; fi
  sleep 0.2
done
[[ "$ready" == true ]]
nix store verify --store "http://127.0.0.1:$port/smoke" \
  --sigs-needed 1 --trusted-public-keys "$public_key" "$second"
printf 'PASS: check-config, JWT token-file auth, push, signed NAR download, watch-store upload\n'
