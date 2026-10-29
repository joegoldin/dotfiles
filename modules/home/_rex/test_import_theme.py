#!/usr/bin/env python3
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("import-theme.py")


class ThemeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.theme = self.root / "Gruvbox Dark Hard"
        self.theme.write_text("background = #1d2021\n")
        self.stamp = self.root / "state" / "stamp"
        self.log = self.root / "calls"
        self.rex = self.root / "rex"
        self.rex.write_text(f'''#!{sys.executable}
import json, os, sys
with open(os.environ["CALLS"], "a") as f:
    f.write(json.dumps(sys.argv[1:]) + "\\n")
mode = os.environ.get("MODE", "ok")
if "ls" in sys.argv:
    if mode == "invalid": print("not JSON")
    else: print(json.dumps({{"clients": [] if mode == "absent" else [{{"client_id": "client:1", "info": {{"kind": "app"}}}}]}}))
elif mode == "denied": sys.exit(1)
''')
        self.rex.chmod(0o700)

    def run_import(self, mode="ok"):
        return subprocess.run([sys.executable, str(SCRIPT), str(self.rex), str(self.theme), str(self.stamp)],
                              env={**os.environ, "CALLS": str(self.log), "MODE": mode}, capture_output=True, text=True)

    def test_import_select_and_skip_unchanged_import(self):
        self.assertEqual(self.run_import().returncode, 0)
        self.assertTrue(self.stamp.exists())
        calls = self.log.read_text()
        self.assertIn("client.theme.import", calls)
        self.assertIn("client.theme.change", calls)
        self.assertEqual(self.run_import().returncode, 0)
        self.assertEqual(self.log.read_text().count("client.theme.import"), 1)
        self.assertEqual(self.log.read_text().count("client.theme.change"), 2)
        self.theme.write_text("background = #282828\n")
        self.assertEqual(self.run_import().returncode, 0)
        self.assertEqual(self.log.read_text().count("client.theme.import"), 2)

    def test_absent_app_defers_without_stamp(self):
        result = self.run_import("absent")
        self.assertEqual(result.returncode, 0)
        self.assertIn("pending", result.stdout)
        self.assertFalse(self.stamp.exists())

    def test_denied_action_fails_without_stamp(self):
        self.assertNotEqual(self.run_import("denied").returncode, 0)
        self.assertFalse(self.stamp.exists())

    def test_invalid_json_reports_error_without_stamp(self):
        result = self.run_import("invalid")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Cannot read Rex client list", result.stderr)
        self.assertFalse(self.stamp.exists())


if __name__ == "__main__":
    unittest.main()
