#!/usr/bin/env python3
import json
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest


LAUNCHER = Path(__file__).with_name("launchd.py")


class LaunchdSupervisorTest(unittest.TestCase):
    def test_propagates_exit_status(self):
        for status in (0, 7):
            result = subprocess.run(
                [sys.executable, LAUNCHER, sys.executable, "-c", f"raise SystemExit({status})"],
                timeout=10,
            )
            self.assertEqual(result.returncode, status)

    def test_detaches_server_and_forwards_stop(self):
        probe = """
import json, os, signal, sys
from pathlib import Path
signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
ready = Path(sys.argv[1])
temporary = ready.with_suffix(".tmp")
temporary.write_text(json.dumps([os.getpid(), os.getsid(0)]))
temporary.replace(ready)
signal.pause()
"""
        with tempfile.TemporaryDirectory() as directory:
            ready = Path(directory) / "ready"
            with subprocess.Popen(
                [sys.executable, LAUNCHER, sys.executable, "-c", probe, ready],
                start_new_session=True,
            ) as supervisor:
                try:
                    deadline = time.monotonic() + 5
                    while not ready.exists():
                        self.assertIsNone(supervisor.poll())
                        self.assertLess(time.monotonic(), deadline, "server did not start")
                        time.sleep(0.01)
                    pid, sid = json.loads(ready.read_text())
                    self.assertEqual(pid, sid, "remote attach requires a session leader")
                    self.assertNotEqual(pid, supervisor.pid)
                    supervisor.send_signal(signal.SIGTERM)
                    self.assertEqual(supervisor.wait(timeout=5), 0)
                finally:
                    if supervisor.poll() is None:
                        supervisor.terminate()
                        supervisor.wait(timeout=5)


if __name__ == "__main__":
    unittest.main()
