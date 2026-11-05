#!/usr/bin/env python3
import json
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
        self.local_app = {
            "client_id": "client:mac",
            "info": {"kind": "app", "platform": "macos"},
            "principal": {"kind": "peer", "transport": "unix"},
        }
        self.remote_linux = {
            "client_id": "client:linux",
            "info": {"kind": "app", "platform": "linux"},
            "principal": {"kind": "tailscale", "transport": "tailscale"},
        }
        self.rex.write_text(f'''#!{sys.executable}
import json, os, sys
with open(os.environ["CALLS"], "a") as f:
    f.write(json.dumps(sys.argv[1:]) + "\\n")
mode = os.environ.get("MODE", "ok")
if "ls" in sys.argv:
    if mode == "invalid": print("not JSON")
    else: print(json.dumps({{"clients": [] if mode == "absent" else json.loads(os.environ["CLIENTS"])}}))
elif mode == "denied" or (mode == "change-denied" and "client.theme.change" in sys.argv): sys.exit(1)
elif "-C" in sys.argv and sys.argv[sys.argv.index("-C") + 1] != "client:mac": sys.exit(1)
''')
        self.rex.chmod(0o700)

    def run_import(self, mode="ok", clients=None):
        clients = [self.local_app] if clients is None else clients
        return subprocess.run([sys.executable, str(SCRIPT), str(self.rex), str(self.theme), str(self.stamp)],
                              env={**os.environ, "CALLS": str(self.log), "MODE": mode,
                                   "CLIENTS": json.dumps(clients)}, capture_output=True, text=True)

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

    def test_remote_linux_first_selects_local_mac(self):
        result = self.run_import(clients=[self.remote_linux, self.local_app])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.stamp.exists())
        self.assertIn('client:mac', self.log.read_text())
        self.assertNotIn('client:linux', self.log.read_text())

    def test_remote_mac_first_selects_local_mac(self):
        remote_mac = {
            "client_id": "client:remote-mac",
            "info": {"kind": "app", "platform": "macos"},
            "principal": {"kind": "tailscale", "transport": "tailscale"},
        }
        result = self.run_import(clients=[remote_mac, self.local_app])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.stamp.exists())
        self.assertNotIn('client:remote-mac', self.log.read_text())

    def test_only_remote_app_defers_without_stamp(self):
        result = self.run_import(clients=[self.remote_linux])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("pending", result.stdout)
        self.assertFalse(self.stamp.exists())
        self.assertNotIn('"-C"', self.log.read_text())

    def test_mac_without_transport_defers_without_stamp(self):
        unknown_mac = {"client_id": "client:unknown", "info": self.local_app["info"]}
        result = self.run_import(clients=[unknown_mac])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("pending", result.stdout)
        self.assertFalse(self.stamp.exists())
        self.assertNotIn('"-C"', self.log.read_text())

    def test_absent_app_defers_without_stamp(self):
        result = self.run_import("absent")
        self.assertEqual(result.returncode, 0)
        self.assertIn("pending", result.stdout)
        self.assertFalse(self.stamp.exists())

    def test_denied_action_fails_without_stamp(self):
        self.assertNotEqual(self.run_import("denied").returncode, 0)
        self.assertFalse(self.stamp.exists())

    def test_change_failure_is_not_hidden_or_stamped(self):
        self.assertNotEqual(self.run_import("change-denied").returncode, 0)
        self.assertIn("client.theme.import", self.log.read_text())
        self.assertIn("client.theme.change", self.log.read_text())
        self.assertFalse(self.stamp.exists())

    def test_invalid_json_reports_error_without_stamp(self):
        result = self.run_import("invalid")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Cannot read Rex client list", result.stderr)
        self.assertFalse(self.stamp.exists())


if __name__ == "__main__":
    unittest.main()
