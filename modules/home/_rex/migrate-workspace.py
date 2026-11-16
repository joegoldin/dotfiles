#!/usr/bin/env python3
"""Carry preferences across the Rex Rune to Rex Linux directory rename."""

from pathlib import Path
import sys


def main():
    root = Path(sys.argv[1])
    old = root / "rex-rune/workspace.json"
    new = root / "rex-linux/workspace.json"
    if not old.is_file() or new.exists():
        return
    original = old.read_bytes()
    new.parent.mkdir(parents=True, exist_ok=True)
    # Never replace preferences already saved by the new client.
    try:
        with new.open("xb") as stream:
            stream.write(original)
    except FileExistsError:
        pass


if __name__ == "__main__":
    main()
