#!/usr/bin/env python3
import os
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

    def run_migration(self, root):
        subprocess.run([sys.executable, str(SCRIPT), str(root)], check=True,
                       env={**os.environ, "PYTHONDONTWRITEBYTECODE": "1"})


if __name__ == "__main__":
    unittest.main()
