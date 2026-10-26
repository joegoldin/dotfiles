#!/usr/bin/env python3
import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("vortex_nxm", Path(__file__).with_name("vortex_nxm.py"))
vortex_nxm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vortex_nxm)


class VortexLinkTests(unittest.TestCase):
    def test_reuses_matching_wine_runtime(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            prefix = root / "prefix"
            prefix.mkdir()
            process = root / "123"
            process.mkdir()
            (process / "comm").write_text("wineserver\n")
            (process / "environ").write_bytes(f"WINEPREFIX={prefix}\0".encode())
            (process / "exe").symlink_to("/proton/files/bin/wineserver")
            self.assertEqual(vortex_nxm.find_runtime(prefix, root), (123, Path("/proton/files/bin/wine")))
            with self.assertRaisesRegex(RuntimeError, "Open Vortex"):
                vortex_nxm.find_runtime(root / "other-prefix", root)

    def test_ambiguous_servers_are_not_guessed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for pid in (123, 456):
                process = root / str(pid)
                process.mkdir()
                (process / "comm").write_text("wineserver\n")
                (process / "environ").write_bytes(b"WINEPREFIX=/prefix\0")
                (process / "exe").symlink_to("/proton/files/bin/wineserver")
            with self.assertRaisesRegex(RuntimeError, "Multiple"):
                vortex_nxm.find_runtime(Path("/prefix"), root)

    def test_url_is_one_argument_and_no_stl_setup_is_run(self):
        url = "nxm://newvegas/mods/123/files/456?key=test&expires=123"
        command = vortex_nxm.forward_command("nsenter", 123, Path("/proton/bin/wine"), Path("/prefix"), Path("/prefix/Vortex.exe"), url)
        self.assertEqual(command[:6], ["nsenter", "--target", "123", "--user", "--mount", "--preserve-credentials"])
        self.assertEqual(command[-2:], ["--download", url])
        self.assertNotIn("steamtinkerlaunch", command)
        self.assertNotIn("--set", command)

    def test_does_not_leak_linux_dotnet_roots(self):
        command = vortex_nxm.forward_command("nsenter", 123, Path("/wine"), Path("/prefix"), Path("/Vortex.exe"), "nxm://newvegas/mods/1/files/2")
        for variable in ("DOTNET_ROOT", "DOTNET_ROOT_X64", "DOTNET_ROOT_X86", "DOTNET_ROOT(x86)"):
            index = command.index(variable)
            self.assertEqual(command[index - 1], "-u")

    def test_rejects_other_url_schemes(self):
        with self.assertRaisesRegex(ValueError, "Nexus"):
            vortex_nxm.validate_url("https://example.com")
        vortex_nxm.validate_url("nxm://newvegas/mods/123/files/456")


if __name__ == "__main__":
    unittest.main()
