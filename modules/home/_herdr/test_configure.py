import importlib.util
from pathlib import Path
import tempfile
import unittest

import tomlkit

spec = importlib.util.spec_from_file_location("configure", Path(__file__).with_name("configure.py"))
configure = importlib.util.module_from_spec(spec)
spec.loader.exec_module(configure)


class ConfigureTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name) / "config.toml"

    def test_preserves_history_comments_and_unmanaged_preferences(self):
        self.path.write_text(
            '# Keep local history.\n[experimental]\npane_history = true\n'
            '[theme]\nname = "nord"\n[theme.custom]\nred = "#ff0000"\n'
            '[updates]\nenabled = true\n'
        )
        configure.configure(self.path, {"theme": {"name": "gruvbox", "custom": {"panel_bg": "#1d2021"}}})
        result = self.path.read_text()
        parsed = tomlkit.parse(result)
        self.assertIn("# Keep local history.", result)
        self.assertTrue(parsed["experimental"]["pane_history"])
        self.assertTrue(parsed["updates"]["enabled"])
        self.assertEqual(parsed["theme"]["custom"]["red"], "#ff0000")
        self.assertEqual(parsed["theme"]["custom"]["panel_bg"], "#1d2021")

    def test_does_not_claim_user_shortcuts_or_duplicate_actions(self):
        self.path.write_text(
            '[[keys.command]]\nkey = "prefix+N"\ncommand = "custom"\n'
            '[[keys.command]]\nkey = "prefix+X"\ncommand = "memex"\n'
        )
        bindings = {"keys": {"command": [
            {"key": "prefix+N", "command": "navigator"},
            {"key": "prefix+M", "command": "memex"},
            {"key": "prefix+E", "command": "ttt"},
        ]}}
        configure.configure(self.path, bindings)
        commands = tomlkit.parse(self.path.read_text())["keys"]["command"]
        self.assertEqual([item["command"] for item in commands], ["custom", "memex", "ttt"])
        before = self.path.stat().st_mtime_ns
        configure.configure(self.path, bindings)
        self.assertEqual(before, self.path.stat().st_mtime_ns)

    def test_new_config_is_private_and_does_not_set_history(self):
        configure.configure(self.path, {"theme": {"name": "gruvbox"}})
        self.assertEqual(self.path.stat().st_mode & 0o777, 0o600)
        self.assertNotIn("experimental", tomlkit.parse(self.path.read_text()))

    def test_keeps_existing_mode_and_symlink(self):
        target = self.path.with_name("target.toml")
        target.write_text("unmanaged = true\n")
        target.chmod(0o640)
        self.path.symlink_to(target)
        configure.configure(self.path, {"theme": {"name": "gruvbox"}})
        self.assertTrue(self.path.is_symlink())
        self.assertEqual(target.stat().st_mode & 0o777, 0o640)
        self.assertTrue(tomlkit.parse(target.read_text())["unmanaged"])

    def test_invalid_config_is_left_untouched(self):
        existing = "[broken\n"
        self.path.write_text(existing)
        with self.assertRaises(tomlkit.exceptions.TOMLKitError):
            configure.configure(self.path, {"theme": {"name": "gruvbox"}})
        self.assertEqual(self.path.read_text(), existing)


if __name__ == "__main__":
    unittest.main()
