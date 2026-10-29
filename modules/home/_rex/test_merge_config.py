#!/usr/bin/env python3
import importlib.util
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("merge-config.py")
spec = importlib.util.spec_from_file_location("merge_config", SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class MergeTests(unittest.TestCase):
    def test_preserves_local_and_is_idempotent(self):
        local = '-- local\nrex.bind("cmd+d", "pane.zoom")\n'
        merged = module.merge(local, "/config/dotfiles.lua")
        self.assertTrue(merged.endswith(local))
        self.assertEqual(module.merge(merged, "/config/dotfiles.lua"), merged)
        self.assertIn("/new/dotfiles.lua", module.merge(merged, "/new/dotfiles.lua"))

    def test_refuses_malformed_markers(self):
        for text in [module.BEGIN, module.END, module.END + module.BEGIN,
                     module.BEGIN * 2 + module.END]:
            with self.assertRaises(ValueError):
                module.merge(text, "/config/dotfiles.lua")

    def test_validation_failure_preserves_file(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "init.lua"
            path.write_text("-- local\n")
            result = subprocess.run([sys.executable, str(SCRIPT), str(path),
                                     "/config/dotfiles.lua", shutil.which("false")], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(path.read_text(), "-- local\n")
            self.assertEqual(list(Path(directory).iterdir()), [path])

    def test_success_creates_backup_once(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "init.lua"
            path.write_text("-- local\n")
            command = [sys.executable, str(SCRIPT), str(path),
                       "/config/dotfiles.lua", shutil.which("true")]
            subprocess.run(command, check=True)
            subprocess.run(command, check=True)
            backups = list(Path(directory).glob("init.lua.backup-*"))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_text(), "-- local\n")
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)


if __name__ == "__main__":
    unittest.main()
