#!/usr/bin/env python3
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import tempfile
import time
import unittest

import recorder as rec


class RecorderTests(unittest.TestCase):
    def test_deltas(self):
        a = [0] * 17
        b = [0] * 17
        b[4], b[6], b[7], b[8], b[10] = 2, 8, 600, 1, 3000
        before = (10, {'some': 10, 'full': 0}, {'root': a}, {'nix': (8, 20), 'reset': (0, 10)})
        after = (12, {'some': 500010, 'full': 100000}, {'root': b}, {'nix': (8, 220), 'reset': (0, 4), 'new': (0, 2000)})
        before[2]['disk'] = a
        after[2]['disk'] = b
        b[15:17] = [2, 600]
        memory = {'dirty_bytes': 4096, 'writeback_bytes': 8192}
        s = rec.interval((*before, {'system.slice': (0, 5)}, {}),
                         (*after, {'system.slice': (7, 12)}, memory))
        self.assertEqual(s['devices']['disk']['flushes'], 2)
        self.assertEqual(s['devices']['disk']['flush_total_ms'], 600)
        self.assertEqual(s['devices']['disk']['flush_ms'], 300)
        self.assertEqual(s['memory'], memory)
        self.assertEqual(s['slices']['system.slice'], {'read_bytes': 7, 'write_bytes': 7})
        self.assertEqual(s['units'], {'nix': {'read_bytes': 0, 'write_bytes': 200}})
        self.assertEqual(s['devices']['root'], dict(read_ms=None, write_ms=300, write_bytes=4096, read_bytes=0, queue=1.5, inflight=1))
        self.assertEqual(s['psi_pct'], {'some': 25, 'full': 5})
        self.assertEqual(rec.triggers(s), ['io-pressure', 'root-latency', 'disk-latency'])
        s['postgres'] = {'ms': 20, 'status': 'error'}
        self.assertIn('postgres', rec.triggers(s))

    def test_rolling_history_survives_restart(self):
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / 'history.sqlite'
            db = rec.open_history(p)
            now = 1000000
            times = [now-rec.RETENTION-1, now-rec.RETENTION, now-7*86400, now]
            rec.flush(db, [(t, '', '{}') for t in times], now, False)
            db.close()
            db = rec.open_history(p)
            rec.flush(db, [], now, True)
            self.assertEqual([r[0] for r in db.execute('SELECT ts FROM samples ORDER BY ts')], times[1:])
            db.close()

    def test_sync_probe(self):
        with tempfile.TemporaryDirectory() as td:
            path = Path(td) / 'probe.block'
            for _ in range(2):
                self.assertEqual(rec.sync_probe(path)['status'], 'ok')
                self.assertEqual(path.stat().st_size, 4096)
            sample = {'psi_pct': {'full': 0}, 'devices': {}, 'sync': rec.sync_probe(Path(td))}
            self.assertEqual(sample['sync']['status'], 'error')
            self.assertEqual(rec.triggers(sample), ['durable-write'])

    def test_probe(self):
        for code, status in [('print(1)', 'ok'), ('print(2)', 'error'), ('raise SystemExit(1)', 'error'), ('import time;time.sleep(5)', 'timeout')]:
            self.assertEqual(rec.probe([sys.executable, '-c', code])['status'], status)

    @unittest.skipUnless(sys.platform == 'linux', 'requires Linux PSI and cgroups')
    def test_live_sampler(self):
        # Run the actual loop with real counters, then ensure SIGTERM flushes
        # even when less than a normal write batch has accumulated.
        with tempfile.TemporaryDirectory() as td:
            proc = subprocess.Popen([sys.executable, rec.__file__, sys.executable, '-c', 'print(1)'],
                                    env={**os.environ, 'STATE_DIRECTORY': td})
            try:
                time.sleep(6)
                proc.terminate()
                self.assertEqual(proc.wait(timeout=5), 0)
                with sqlite3.connect(Path(td)/'history.sqlite') as db:
                    n, probes = db.execute("SELECT count(*),count(json_extract(data,'$.postgres.ms')) FROM samples").fetchone()
                    self.assertGreaterEqual(n, 2)
                    self.assertGreaterEqual(probes, 1)
                    row = db.execute("SELECT json_extract(data,'$.sync.status'), json_extract(data,'$.memory.dirty_bytes'), json_type(data,'$.slices'), json_type(data,'$.devices.disk.flushes') FROM samples WHERE json_type(data,'$.sync') IS NOT NULL").fetchone()
                    self.assertIsNotNone(row)
                    self.assertEqual(row[0], 'ok')
                    self.assertGreaterEqual(row[1], 0)
                    self.assertEqual(row[2:], ('object', 'integer'))
            finally:
                if proc.poll() is None:
                    proc.kill()
                    proc.wait()


if __name__ == '__main__':
    unittest.main()
