#!/usr/bin/env bash
set -euo pipefail

: "${ACCESS_TOKEN:?Runner registration PAT is required}"
: "${REPO_URL:?Runner repository URL is required}"
: "${RUNNER_NAME:?Runner name is required}"
: "${LABELS:?Runner labels are required}"

# The previous image ran as root; migrate its cache to the official image's user.
if [[ -d /opt/sccache && ! -w /opt/sccache ]]; then
  sudo -n chown -R "$(id -u):$(id -g)" /opt/sccache
fi

repo="${REPO_URL#https://github.com/}"
# Read the authorization header from stdin, not the process command line.
registration_token=$(
  curl --fail --silent --show-error --request POST \
    --header "Accept: application/vnd.github+json" \
    --config - "https://api.github.com/repos/${repo}/actions/runners/registration-token" <<EOF | jq -er '.token | select(type == "string" and length > 0)'
header = "Authorization: Bearer ${ACCESS_TOKEN}"
EOF
)
# Neither configuration nor build jobs need the long-lived PAT.
unset ACCESS_TOKEN

./config.sh --unattended --replace --ephemeral \
  --url "$REPO_URL" --token "$registration_token" \
  --name "$RUNNER_NAME" --labels "$LABELS" --work _work
unset registration_token

# Do not pass --disableupdate: GitHub stops assigning jobs to obsolete runners.
exec ./run.sh
