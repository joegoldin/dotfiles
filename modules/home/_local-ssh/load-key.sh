# Invoked by a one-shot login service, never by a shell or SSH connection.
set -euo pipefail

key=$1
export SSH_KEY_PASSPHRASE_FILE=$2

if [[ ! -r "$key" || ! -r "$SSH_KEY_PASSPHRASE_FILE" ]]; then
    echo "SSH login key or agenix passphrase is missing or unreadable." >&2
    exit 1
fi

# launchd does not order sibling agents; allow the agent time to bind its socket.
ready=false
for ((attempt = 0; attempt < 100; attempt++)); do
    status=0
    ssh-add -l >/dev/null 2>&1 || status=$?
    if ((status < 2)); then
        ready=true
        break
    fi
    sleep 0.1
done
if [[ "$ready" != true ]]; then
    echo "SSH agent did not become ready within 10 seconds." >&2
    exit 1
fi

export SSH_ASKPASS=@askpass@
export SSH_ASKPASS_REQUIRE=force
export DISPLAY=${DISPLAY:-ssh-login}
# The helper recognizes the initial English prompt and refuses retry prompts.
export LC_ALL=C
# The agent itself also has no default lifetime; -t 0 alone cannot override one.
exec ssh-add -t 0 "$key" </dev/null
