"""Merge managed TOML settings without replacing unrelated user preferences."""

import json
import os
from pathlib import Path
import stat
import sys
import tempfile

import tomlkit


def merge(document, settings):
    for key, value in settings.items():
        if isinstance(value, dict):
            if key not in document:
                document[key] = tomlkit.table()
            merge(document[key], value)
        elif key == "command" and isinstance(value, list):
            # Keep user-selected shortcuts; add only unclaimed defaults.
            commands = document.get(key, [])
            for binding in value:
                if not any(
                    item.get("key") == binding["key"]
                    or item.get("command") == binding["command"]
                    for item in commands
                ):
                    commands.append(binding)
            document[key] = commands
        else:
            document[key] = value


def configure(path, settings):
    path = Path(path).resolve()
    existing = path.read_text() if path.exists() else ""
    document = tomlkit.parse(existing)
    merge(document, settings)
    updated = tomlkit.dumps(document)
    if updated == existing:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o600
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as handle:
            temporary = Path(handle.name)
            handle.write(updated)
            handle.flush()
            os.fchmod(handle.fileno(), mode)
        temporary.replace(path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: configure.py SETTINGS.json")
    try:
        for entry in json.loads(Path(sys.argv[1]).read_text()):
            configure(entry["path"], entry["settings"])
    except (OSError, ValueError, TypeError, tomlkit.exceptions.TOMLKitError) as error:
        raise SystemExit(f"Herdr configuration was not applied: {error}") from error
