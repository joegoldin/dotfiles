#!/usr/bin/env python3
"""Exercise Justfile wiring without updating packages or touching the real store."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[3]
JUST = shutil.which("just")


class ToolRecipes(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.work = Path(self.tmp.name)
        shutil.copy(ROOT / "Justfile", self.work / "Justfile")
        self.log = self.work / "calls"
        self.bin = self.work / "bin"
        self.bin.mkdir()
        self.env = os.environ | {
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "CALL_LOG": str(self.log),
        }
        for name in ("nix", "nix-fast-build", "nix-update", "sudo"):
            script = self.bin / name
            script.write_text(
                "#!/usr/bin/env bash\n"
                'printf "%s\\n" "$(basename "$0") $*" >> "$CALL_LOG"\n'
                'case "$(basename "$0")" in\n'
                '  nix) if [[ "$*" == *"flake check"* ]]; then exit "${VALIDATE_RC:-0}"; fi ;;\n'
                '  nix-fast-build) exit "${BUILD_RC:-0}" ;;\n'
                '  nix-update) [[ "$*" != *broken* ]] || exit 1 ;;\n'
                "esac\n"
            )
            script.chmod(0o755)

    def run_recipe(self, *args, **env):
        return subprocess.run(
            [JUST, *args], cwd=self.work, env=self.env | env,
            text=True, capture_output=True,
        )

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_check_validates_before_parallel_build(self):
        result = self.run_recipe("check")
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.calls()
        self.assertEqual(len(calls), 3, calls)
        self.assertIn("flake check --no-build", calls[1])
        self.assertIn("--show-trace", calls[1])
        self.assertTrue(calls[2].startswith("nix-fast-build --flake .#checks."))
        self.assertIn("--impure --eval-workers 2 --max-jobs 2", calls[2])

    def test_validation_failure_stops_build(self):
        result = self.run_recipe("check", VALIDATE_RC="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(c.startswith("nix-fast-build") for c in self.calls()))
        self.assertNotIn("Check completed!", result.stdout)

    def test_build_failure_is_not_success(self):
        result = self.run_recipe("check", BUILD_RC="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("Check completed!", result.stdout)

    def test_fast_build_forwards_target_and_flags(self):
        result = self.run_recipe("fast-build", "packages", "--no-link")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--flake .#packages.", self.calls()[0])
        self.assertTrue(self.calls()[0].endswith("--no-link"))

    def test_update_uses_installed_tool(self):
        result = self.run_recipe("update-pkgs", "example")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["nix-update --flake example"])

    def test_update_failure_continues_but_fails_recipe(self):
        result = self.run_recipe("update-pkgs", "broken", "example")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), ["nix-update --flake broken", "nix-update --flake example"])

    def test_gc_defaults_to_preview_without_pruning_generations(self):
        result = self.run_recipe("nix-gc-fast")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["sudo fast-nix-gc --dry-run --no-vacuum"])

    def test_gc_collection_requires_explicit_mode(self):
        result = self.run_recipe("nix-gc-fast", "collect")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), ["sudo fast-nix-gc --no-vacuum"])

    def test_invalid_gc_mode_does_not_touch_store(self):
        result = self.run_recipe("nix-gc-fast", "typo")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [])


if __name__ == "__main__":
    unittest.main()
