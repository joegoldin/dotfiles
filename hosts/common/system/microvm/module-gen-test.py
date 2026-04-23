"""Golden-file tests for module-gen.py.

Run with: python3 -m pytest module-gen-test.py -v
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
GEN = HERE / "module-gen.py"
PROFILES = HERE / "profiles"
REPO_ROOT = HERE.parent.parent.parent.parent  # hosts/common/system/microvm -> repo root
FIXTURE_CLI_PUB = HERE / "test-data" / "fixture-cli.pub"
FIXTURE_USER_PUB = HERE / "test-data" / "fixture-user.pub"


def run_gen(meta_path: Path, out_dir: Path) -> None:
    subprocess.run(
        [
            sys.executable,
            str(GEN),
            "--meta", str(meta_path),
            "--out", str(out_dir),
            "--profiles-dir", str(PROFILES),
            "--repo-root", str(REPO_ROOT),
            "--cli-pub", str(FIXTURE_CLI_PUB),
            "--user-pub", str(FIXTURE_USER_PUB),
        ],
        check=True,
    )


def assert_golden(tmp_path: Path, fixture: str) -> None:
    for artifact in ("module.nix", "flake.nix"):
        got = (tmp_path / artifact).read_text()
        want_path = HERE / "test-data" / f"{fixture}.{artifact}.expected"
        want = want_path.read_text()
        assert got == want, (
            f"{artifact} differs from {want_path}:\n"
            f"--- want\n{want}\n--- got\n{got}\n"
        )


def test_minimal_basic(tmp_path: Path) -> None:
    run_gen(HERE / "test-data" / "minimal-basic.meta.json", tmp_path)
    assert_golden(tmp_path, "minimal-basic")


def test_desktop_full(tmp_path: Path) -> None:
    run_gen(HERE / "test-data" / "desktop-full.meta.json", tmp_path)
    assert_golden(tmp_path, "desktop-full")
