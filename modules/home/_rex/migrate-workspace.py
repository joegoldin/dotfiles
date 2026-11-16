#!/usr/bin/env python3
"""Migrate Rex preferences, preserving unsupported SSH hosts in a backup."""

from pathlib import Path
import json
import os
import sys


def main():
    root = Path(sys.argv[1])
    old = root / "rex-rune/workspace.json"
    new = root / "rex-linux/workspace.json"
    if new.exists():
        repair_hosts(new)
        return
    if not old.is_file():
        return
    original = old.read_bytes()
    new.parent.mkdir(parents=True, exist_ok=True)
    # Never replace preferences already saved by the new client.
    try:
        with new.open("xb") as stream:
            stream.write(original)
    except FileExistsError:
        pass

    repair_hosts(new)


def repair_hosts(path):
    # Rex Rune accepted SSH hosts; Rex Linux only accepts HTTP(S) and Unix sockets.
    original = path.read_bytes()
    try:
        workspace = json.loads(original)
    except (ValueError, UnicodeDecodeError):
        return
    hosts = workspace.get("hosts", [])
    supported = [host for host in hosts if not host.get("endpoint", "").startswith("ssh://")]
    if supported == hosts:
        return
    backup = path.with_suffix(".json.unsupported-hosts.bak")
    if not backup.exists():
        with backup.open("xb") as stream:
            stream.write(original)
    workspace["hosts"] = supported
    if (workspace.get("last_host") or "").startswith("ssh://"):
        workspace["last_host"] = supported[0]["endpoint"] if supported else None
    temporary = path.with_suffix(".json.tmp")
    temporary.write_text(json.dumps(workspace, indent=2) + "\n")
    os.replace(temporary, path)


if __name__ == "__main__":
    main()
