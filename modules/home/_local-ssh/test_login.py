"""Exercise the real loader with disposable keys and an isolated agent."""

import os
import shlex
from pathlib import Path
import subprocess
import tempfile
import unittest


class LoaderTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="ssh-login-test-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.key = self.root / "key"
        self.secret = self.root / "passphrase"
        self.secret.write_text("synthetic test passphrase")
        self.secret.chmod(0o600)
        subprocess.run([
            "ssh-keygen", "-q", "-t", "ed25519", "-N",
            "synthetic test passphrase", "-f", str(self.key),
        ], check=True)
        self.env = dict(os.environ, SSH_AUTH_SOCK=str(self.root / "ssh-agent"))
        # Exercise the evaluated service command, not a separate test agent config.
        command = os.environ["SSH_LOGIN_AGENT_COMMAND"].replace("%t", str(self.root))
        self.agent = subprocess.Popen(
            shlex.split(command), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        self.addCleanup(self.stop_agent)

    def stop_agent(self):
        self.agent.terminate()
        self.agent.wait(timeout=5)

    def load(self, secret=None):
        return subprocess.run([
            os.environ["SSH_LOGIN_LOADER"], str(self.key), str(secret or self.secret),
        ], env=self.env, capture_output=True, text=True, timeout=20)

    def test_unlock_no_expiry_manual_removal_and_agent_exit(self):
        result = self.load()
        self.assertEqual(result.returncode, 0, result.stderr)
        subprocess.run(["ssh-add", "-T", str(self.key) + ".pub"], env=self.env, check=True)
        # Together with the Nix assertions on the absence of a default lifetime,
        # verify the real service command keeps the key available after loading.
        subprocess.run(["sleep", "2"], check=True)
        listed = subprocess.run(["ssh-add", "-l"], env=self.env, capture_output=True)
        self.assertEqual(listed.returncode, 0)
        subprocess.run(["ssh-add", "-d", str(self.key) + ".pub"], env=self.env, check=True)
        listed = subprocess.run(["ssh-add", "-l"], env=self.env, capture_output=True)
        self.assertEqual(listed.returncode, 1)
        self.assertEqual(self.load().returncode, 0)
        self.stop_agent()
        listed = subprocess.run(["ssh-add", "-l"], env=self.env, capture_output=True)
        self.assertEqual(listed.returncode, 2)

    def test_missing_secret_fails_without_prompt(self):
        result = self.load(self.root / "missing")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing or unreadable", result.stderr)

    def test_wrong_passphrase_fails_without_leaking_it(self):
        self.secret.write_text("synthetic wrong passphrase")
        result = self.load()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("synthetic wrong passphrase", result.stdout + result.stderr)



if __name__ == "__main__":
    unittest.main()
