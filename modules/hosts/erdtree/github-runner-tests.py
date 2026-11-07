#!/usr/bin/env python3
"""Exercise runner registration without contacting GitHub or using credentials."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


STARTUP = Path(__file__).with_name("github-runner-start.sh")


class RunnerStartupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.env = {
            **os.environ,
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "ACCESS_TOKEN": "fixture-access-token",
            "REPO_URL": "https://github.com/joegoldin/zen-bonsai-browser",
            "RUNNER_NAME": "erdtree",
            "LABELS": "erdtree",
        }
        self.program(
            self.bin / "curl",
            """import json, os, sys
assert 'fixture-access-token' not in ' '.join(sys.argv)
assert 'Authorization: Bearer fixture-access-token' in sys.stdin.read()
assert sys.argv[-1] == 'https://api.github.com/repos/joegoldin/zen-bonsai-browser/actions/runners/registration-token'
if os.environ.get('FAIL_REGISTRATION'):
    sys.exit(22)
print(json.dumps({'token': 'registration-fixture'}))
""",
        )
        self.program(
            self.root / "config.sh",
            """import json, os, sys
from pathlib import Path
Path('config.json').write_text(json.dumps({
    'args': sys.argv[1:], 'pat_present': 'ACCESS_TOKEN' in os.environ,
}))
sys.exit(int(os.environ.get('CONFIG_EXIT', '0')))
""",
        )
        self.program(
            self.root / "run.sh",
            """import json, os, sys
from pathlib import Path
Path('run.json').write_text(json.dumps({'pat_present': 'ACCESS_TOKEN' in os.environ}))
sys.exit(int(os.environ.get('RUNNER_EXIT', '0')))
""",
        )

    def program(self, path, body):
        path.write_text("#!/usr/bin/env python3\n" + body)
        path.chmod(0o755)

    def start(self):
        self.assertTrue(STARTUP.is_file(), "official image needs a registration entrypoint")
        return subprocess.run(
            ["bash", str(STARTUP)], cwd=self.root, env=self.env,
            capture_output=True, text=True,
        )

    def test_ephemeral_registration_keeps_updates_and_hides_pat(self):
        result = self.start()
        self.assertEqual(result.returncode, 0, result.stderr)
        config = json.loads((self.root / "config.json").read_text())
        args = config["args"]
        self.assertIn("--ephemeral", args)
        self.assertIn("--unattended", args)
        self.assertIn("--replace", args)
        self.assertNotIn("--disableupdate", args)
        for flag, expected in [
            ("--url", self.env["REPO_URL"]),
            ("--name", "erdtree"), ("--labels", "erdtree"),
            ("--token", "registration-fixture"), ("--work", "_work"),
        ]:
            self.assertEqual(args[args.index(flag) + 1], expected)
        self.assertFalse(config["pat_present"])
        self.assertFalse(json.loads((self.root / "run.json").read_text())["pat_present"])
        self.assertNotIn("fixture-access-token", result.stdout + result.stderr)
        self.assertNotIn("registration-fixture", result.stdout + result.stderr)

    def test_failed_registration_never_configures_or_starts_runner(self):
        self.env["FAIL_REGISTRATION"] = "1"
        result = self.start()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / "config.json").exists())
        self.assertFalse((self.root / "run.json").exists())

    def test_failed_configuration_never_starts_runner(self):
        self.env["CONFIG_EXIT"] = "3"
        result = self.start()
        self.assertEqual(result.returncode, 3)
        self.assertFalse((self.root / "run.json").exists())

    def test_runner_exit_status_is_preserved(self):
        self.env["RUNNER_EXIT"] = "7"
        self.assertEqual(self.start().returncode, 7)

    def test_missing_pat_fails_without_starting_runner(self):
        del self.env["ACCESS_TOKEN"]
        result = self.start()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / "run.json").exists())


if __name__ == "__main__":
    unittest.main()
