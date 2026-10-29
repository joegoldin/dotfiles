#!/usr/bin/env python3
"""Import a managed Ghostty theme through Rex's supported client API."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys

rex, theme, stamp = sys.argv[1:]
path = Path(theme)
state = Path(stamp)
digest = hashlib.sha256(path.read_bytes()).hexdigest()
imported = state.exists() and state.read_text() == digest
result = subprocess.run([rex, "--autostart=false", "client", "ls", "--json"], capture_output=True, text=True)
if result.returncode:
    print("Rex theme pending: open Rex with Remote Control enabled, then apply again.")
    sys.exit(0)
try:
    clients = json.loads(result.stdout)["clients"]
except (json.JSONDecodeError, KeyError) as error:
    raise SystemExit(f"Cannot read Rex client list: {error}") from error
app = next((client for client in clients if client.get("info", {}).get("kind") == "app"), None)
if app is None:
    print("Rex theme pending: open Rex with Remote Control enabled, then apply again.")
    sys.exit(0)
actions = [] if imported else [("client.theme.import", f"path={path}")]
actions.append(("client.theme.change", f"name={path.name}"))
for action, arg in actions:
    subprocess.run([rex, "--autostart=false", "-C", app["client_id"], "do", action, arg], check=True)
state.parent.mkdir(parents=True, exist_ok=True)
state.write_text(digest)
