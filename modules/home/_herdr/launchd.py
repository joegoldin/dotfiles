#!/usr/bin/env python3
"""Keep launchd supervising Herdr while giving the server its own session."""
import signal
import subprocess
import sys


# Herdr's remote-attach handshake requires getsid(0) == getpid(). launchd
# creates a process group, not a POSIX session; its direct child cannot setsid.
with subprocess.Popen(sys.argv[1:], start_new_session=True) as server:
    def forward_signal(signum, _frame):
        try:
            server.send_signal(signum)
        except ProcessLookupError:
            pass

    signal.signal(signal.SIGTERM, forward_signal)
    signal.signal(signal.SIGINT, forward_signal)
    status = server.wait()

sys.exit(status if status >= 0 else 128 - status)
