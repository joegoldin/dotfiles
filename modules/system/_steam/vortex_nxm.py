#!/usr/bin/env python3
"""Forward Nexus links without opening another Wine server on Vortex's database."""

import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
from urllib.parse import urlsplit


def validate_url(url):
    if urlsplit(url).scheme not in ("nxm", "nxm-protocol"):
        raise ValueError("Expected a Nexus mod-manager link")


def vortex_prefix():
    config = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "steamtinkerlaunch"
    value = "STLCFGDIR/vortex/compatdata"
    for line in (config / "global.conf").read_text().splitlines():
        if line.startswith("VORTEXCOMPDATA="):
            value = shlex.split(line.split("=", 1)[1])[0]
    return Path(value.replace("STLCFGDIR", str(config))).expanduser() / "pfx"


def find_runtime(prefix, proc=Path("/proc")):
    matches = []
    for process in proc.iterdir():
        if not process.name.isdecimal():
            continue
        try:
            if process.stat().st_uid != os.getuid():
                continue
            if (process / "comm").read_text().strip() != "wineserver":
                continue
            environment = dict(
                item.split(b"=", 1)
                for item in (process / "environ").read_bytes().split(b"\0")
                if b"=" in item
            )
            server_prefix = environment.get(b"WINEPREFIX")
            if server_prefix is None or Path(os.fsdecode(server_prefix)).resolve() != prefix.resolve():
                continue
            wine = (process / "exe").readlink().with_name("wine")
            matches.append((int(process.name), wine))
        except (OSError, ValueError):
            # Processes can exit while /proc is being inspected.
            continue
    if not matches:
        raise RuntimeError("Open Vortex through SteamTinkerLaunch first, then click the download again.")
    if len(matches) != 1:
        raise RuntimeError("Multiple Wine servers are using Vortex's prefix. Close duplicate Vortex launches first.")
    return matches[0]


def forward_command(nsenter, pid, wine, prefix, executable, url):
    return [
        nsenter, "--target", str(pid), "--user", "--mount", "--preserve-credentials",
        "--", "env", "-u", "DOTNET_ROOT", "-u", "DOTNET_ROOT_X64",
        "-u", "DOTNET_ROOT_X86", "-u", "DOTNET_ROOT(x86)",
        f"WINEPREFIX={prefix}", "WINEDEBUG=-all", "LD_PRELOAD=", "LD_LIBRARY_PATH=",
        str(wine), str(executable), "--download", url,
    ]


def main():
    try:
        nsenter, url = sys.argv[1:]
        validate_url(url)
        prefix = vortex_prefix()
        pid, wine = find_runtime(prefix)
        executable = prefix / "drive_c/Program Files/Black Tree Gaming Ltd/Vortex/Vortex.exe"
        if not executable.is_file():
            executable = prefix / "drive_c/Program Files/Vortex/Vortex.exe"
        if not executable.is_file():
            raise RuntimeError("Vortex is not installed in the SteamTinkerLaunch prefix.")
        result = subprocess.run(forward_command(nsenter, pid, wine, prefix, executable, url), check=False)
        if result.returncode:
            raise RuntimeError("Vortex link forwarding failed. Check that Vortex is still running.")
    except (OSError, RuntimeError, ValueError) as error:
        # Never print the URL: Nexus download links can contain credentials.
        message = str(error) if isinstance(error, RuntimeError) else "Unable to read the Vortex runtime configuration."
        print(message, file=sys.stderr)
        notify = shutil.which("notify-send")
        if notify:
            subprocess.run([notify, "Vortex download", message], check=False)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
