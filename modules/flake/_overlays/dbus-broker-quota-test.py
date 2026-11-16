#!/usr/bin/env python3
"""Exercise launcher-to-broker quotas on a private, socket-activated bus."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time


def check_quotas(launcher, socket_activate, busctl, connections, byte_limit, fds, matches):
    with tempfile.TemporaryDirectory(prefix="broker-quota-") as directory:
        root = Path(directory)
        socket = root / "bus"
        config = root / "session.conf"
        config.write_text(f"""<busconfig>
  <type>session</type>
  <auth>EXTERNAL</auth>
  <policy context="default">
    <allow send_destination="*"/><allow receive_sender="*"/><allow own="*"/>
  </policy>
  <limit name="max_connections_per_user">{connections}</limit>
  <limit name="max_outgoing_bytes">{byte_limit}</limit>
  <limit name="max_outgoing_unix_fds">{fds}</limit>
  <limit name="max_match_rules_per_connection">{matches}</limit>
</busconfig>
""")
        with (root / "log").open("w+") as log:
            process = subprocess.Popen(
                [socket_activate, "--listen=" + str(socket), launcher,
                 "--config-file=" + str(config)],
                stdout=log, stderr=log,
            )
            try:
                deadline = time.monotonic() + 10
                while not socket.exists():
                    if process.poll() is not None or time.monotonic() > deadline:
                        log.seek(0)
                        raise RuntimeError("Private broker did not start: " + log.read())
                    time.sleep(0.01)
                result = subprocess.run(
                    [busctl, "--address=unix:path=" + str(socket), "--json=short",
                     "call", "org.freedesktop.DBus", "/org/freedesktop/DBus",
                     "org.freedesktop.DBus.Debug.Stats", "GetStats"],
                    capture_output=True, text=True, timeout=10,
                )
                if result.returncode:
                    log.seek(0)
                    raise RuntimeError("Private bus query failed: " + result.stderr + log.read())
                stats = json.loads(result.stdout)["data"][0]
                users = stats["org.bus1.DBus.Debug.Stats.UserAccounting"]["data"]
                quotas = next(row[1] for row in users if row[0] == os.getuid())
                maxima = {name: maximum for name, remaining, maximum in quotas}
                for name, limit in (("Bytes", byte_limit), ("Fds", fds), ("Matches", matches)):
                    expected = min(connections * limit, 2**32 - 1)
                    assert maxima[name] == expected, (name, maxima[name], expected)
                assert maxima["Objects"] == 16 * 1024 * 1024, maxima
                print("Verified private-bus quotas:", maxima)
            finally:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


if __name__ == "__main__":
    # Exercise the NixOS overflow and ordinary, non-overflowing limits.
    check_quotas(*sys.argv[1:], 100000, 1000000000, 250000000, 50000)
    check_quotas(*sys.argv[1:], 64, 8 * 1024 * 1024, 64, 256)
