#!/usr/bin/env python3
import os
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("migrate-workspace.py")


class MigrationTests(unittest.TestCase):
    def test_migrates_preferences_without_changing_old_file(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            old = root / "rex-rune/workspace.json"
            old.parent.mkdir()
            original = '{"hosts": [{"label": "work"}], "chrome_theme": "gruvbox_dark"}\n'
            old.write_text(original)
            self.run_migration(root)
            self.assertEqual((root / "rex-linux/workspace.json").read_text(), original)
            self.assertEqual(old.read_text(), original)

    def test_preserves_existing_new_preferences(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ["rex-rune", "rex-linux"]:
                (root / name).mkdir()
                (root / name / "workspace.json").write_text(name)
            self.run_migration(root)
            self.assertEqual((root / "rex-linux/workspace.json").read_text(), "rex-linux")

    def test_fresh_install_needs_no_migration(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.run_migration(root)
            self.assertEqual(list(root.iterdir()), [])

    def test_repairs_unsupported_ssh_hosts_and_preserves_backup(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / "rex-linux/workspace.json"
            target.parent.mkdir()
            original = json.dumps({
                "hosts": [{"label": "local", "endpoint": "unix:///run/rex.sock"},
                          {"label": "remote", "endpoint": "ssh://remote"}],
                "last_host": "ssh://remote", "font_size": 15,
                "sessions": {"ssh://remote": "saved-session"},
            })
            target.write_text(original)
            self.run_migration(root)
            repaired = json.loads(target.read_text())
            self.assertEqual(repaired["hosts"], [{"label": "local", "endpoint": "unix:///run/rex.sock"}])
            self.assertEqual(repaired["last_host"], "unix:///run/rex.sock")
            self.assertEqual(repaired["font_size"], 15)
            self.assertEqual(repaired["sessions"], {"ssh://remote": "saved-session"})
            backup = target.with_suffix(".json.unsupported-hosts.bak")
            self.assertEqual(backup.read_text(), original)
            self.run_migration(root)
            self.assertEqual(backup.read_text(), original)

    def test_repairs_migrated_workspace_with_no_last_host(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            old = root / "rex-rune/workspace.json"
            old.parent.mkdir()
            original = json.dumps({"hosts": [
                {"label": "local", "endpoint": "unix:///run/rex.sock"},
                {"label": "old", "endpoint": "ssh://old"}], "last_host": None})
            old.write_text(original)
            self.run_migration(root)
            repaired = json.loads((root / "rex-linux/workspace.json").read_text())
            self.assertEqual(len(repaired["hosts"]), 1)
            self.assertIsNone(repaired["last_host"])
            self.assertEqual(old.read_text(), original)

    def run_migration(self, root):
        subprocess.run([sys.executable, str(SCRIPT), str(root)], check=True,
                       env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"})


if __name__ == "__main__":
    unittest.main()
