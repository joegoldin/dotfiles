#!/usr/bin/env python3
"""Exercise the evaluated launchd script without Darwin binaries or real credentials."""
import json
import os
from pathlib import Path
import plistlib
import shlex
import stat
import subprocess
import sys
import tempfile
import unittest


class DarwinWatcherTest(unittest.TestCase):
    def test_launchd_supervision(self):
        plist = plistlib.loads(os.environ["CELLER_DARWIN_PLIST"].encode())
        self.assertEqual(plist["Label"], "org.nixos.celler-watch-store")
        self.assertTrue(plist["RunAtLoad"])
        self.assertTrue(plist["KeepAlive"])
        self.assertEqual(plist["ThrottleInterval"], 30)
        self.assertEqual(plist["UserName"], "root")
        self.assertEqual(plist["Umask"], 0o077)
        self.assertEqual(
            plist["EnvironmentVariables"]["XDG_CONFIG_HOME"],
            "/var/run/celler-watch-store",
        )
        self.assertIn("celler-watch-store-start", plist["ProgramArguments"][-1])
        self.assertNotIn("post-build-hook", str(plist))

    def run_script(self, with_token):
        with tempfile.TemporaryDirectory() as directory:
            work = Path(directory)
            token = work / "token"
            if with_token:
                token.write_text("dummy-runtime-token")
            capture = work / "capture.json"
            client = work / "celler"
            client.write_text(
                f"#!{sys.executable}\n"
                "import json, os, sys\n"
                "from pathlib import Path\n"
                "Path(os.environ['WATCHER_CAPTURE']).write_text(\n"
                "    json.dumps({'args': sys.argv[1:], 'pid': os.getpid()}))\n"
            )
            client.chmod(0o700)
            script = os.environ["CELLER_DARWIN_SCRIPT"].replace(
                os.environ["CELLER_DARWIN_TOKEN_PATH"], str(token)
            ).replace(os.environ["CELLER_DARWIN_EXECUTABLE"], shlex.quote(str(client)))
            launcher = work / "start"
            launcher.write_text(script)
            config_home = work / "config"
            process = subprocess.Popen(
                ["bash", str(launcher)],
                env=os.environ | {
                    "XDG_CONFIG_HOME": str(config_home),
                    "WATCHER_CAPTURE": str(capture),
                },
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            stdout, stderr = process.communicate(timeout=10)
            if not with_token:
                self.assertNotEqual(process.returncode, 0)
                self.assertFalse(capture.exists())
                return
            self.assertEqual(process.returncode, 0, stderr.decode())
            launched = json.loads(capture.read_text())
            self.assertEqual(launched["pid"], process.pid, "launchd must supervise the client itself")
            self.assertEqual(launched["args"][:3], ["watch-store", "--jobs", "5"])
            self.assertTrue(launched["args"][3].startswith("default-server:"))
            config = config_home / "celler/config.toml"
            self.assertIn(f'token-file = "{token}"', config.read_text())
            self.assertNotIn("dummy-runtime-token", config.read_text())
            self.assertEqual(stat.S_IMODE(config.stat().st_mode), 0o600)
            self.assertEqual(stat.S_IMODE(config_home.stat().st_mode), 0o700)
            self.assertNotIn(b"dummy-runtime-token", stdout + stderr)

    def test_missing_token_exits_for_launchd_retry(self):
        self.run_script(with_token=False)

    def test_runtime_config_and_direct_exec(self):
        self.run_script(with_token=True)


if __name__ == "__main__":
    unittest.main()
