#!/usr/bin/env python3
"""Check that the MCP adapter augments the shared Pi extension profile."""
import json
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
PROJECTION = """c: {
  packages = map (p: p.pname or p.name) c.extensionPackages;
  defaultTools = c.settings.defaultTools;
  extensions = c.settings.extensions;
  lens = c.finalConfigFiles.\"extensions/pi-lens.json\" or null;
  web = c.finalConfigFiles.\"web-search.json\" or null;
}"""


class PiExtensionProfileTest(unittest.TestCase):
    def test_extensions_and_their_settings_survive_on_both_hosts(self):
        for host in ("nixosConfigurations.elphael", "darwinConfigurations.torrent"):
            with self.subTest(host=host):
                result = subprocess.run(
                    ["nix", "eval", "--no-write-lock-file", "--json",
                     f".#{host}.config.home-manager.users.joe.programs.pi.coding-agent",
                     "--apply", PROJECTION],
                    cwd=ROOT, capture_output=True, text=True, timeout=120,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                profile = json.loads(result.stdout)
                self.assertCountEqual(profile["packages"], [
                    "pi-ext-pi-subagents", "pi-ext-pi-lens",
                    "pi-ext-pi-web-access", "pi-ext-pi-mcp-adapter",
                ])
                self.assertIn("+codemode", profile["defaultTools"])
                self.assertIn("-builtin:mcp", profile["extensions"])
                self.assertIs(profile["lens"]["format"]["enabled"], False)
                self.assertIs(profile["lens"]["autofix"]["enabled"], False)
                self.assertEqual(profile["web"]["provider"], "openai")


if __name__ == "__main__":
    unittest.main()
