#!/usr/bin/env python3
"""Record kernel counter deltas on Erdtree. Do not query the PERC itself."""
import concurrent.futures
import json
import os
from pathlib import Path
import signal
import sqlite3
import subprocess
import sys
import threading
import time

INTERVAL = 2
RETENTION = 8 * 86400
SYS = Path('/sys')
PROC = Path('/proc')


def snapshot(root_dev, disk_dev):
    psi = {p[0]: int(p[-1].split('=')[1]) for line in
           (PROC / 'pressure/io').read_text().splitlines() if (p := line.split())}
    devices = {name: list(map(int, (SYS / 'dev/block' / dev / 'stat').read_text().split()))
               for name, dev in [('root', root_dev), ('disk', disk_dev)]}
    cgroups = SYS / 'fs/cgroup'
    units = cgroup_bytes(cgroups / 'system.slice', disk_dev)
    slices = cgroup_bytes(cgroups, disk_dev)
    memory = {}
    for line in (PROC / 'meminfo').read_text().splitlines():
        key, value = line.split(':', 1)
        if key in ('Dirty', 'Writeback'):
            memory[key.lower() + '_bytes'] = int(value.split()[0]) * 1024
    return time.monotonic(), psi, devices, units, slices, memory


def cgroup_bytes(parent, disk_dev):
    units = {}
    for path in parent.glob('*/io.stat'):
        try:
            for line in path.read_text().splitlines():
                dev, *fields = line.split()
                if dev == disk_dev:  # counting both mapper and disk would double count
                    fields = dict(f.split('=') for f in fields)
                    units[path.parent.name] = (int(fields['rbytes']), int(fields['wbytes']))
                    break
        except FileNotFoundError:  # transient units disappear between list and read
            continue
    return units


def interval(old, new):
    dt = new[0] - old[0]
    psi = {k: round((v - old[1][k]) / dt / 10000, 2) for k, v in new[1].items()}
    devices = {}
    for name, values in new[2].items():
        d = [b - a for a, b in zip(old[2][name], values)]
        devices[name] = dict(read_ms=round(d[3] / d[0], 2) if d[0] else None,
                             write_ms=round(d[7] / d[4], 2) if d[4] else None,
                             read_bytes=d[2] * 512, write_bytes=d[6] * 512,
                             queue=round(d[10] / dt / 1000, 2), inflight=values[8])
        if name == 'disk':
            devices[name].update(flushes=d[15], flush_total_ms=d[16],
                                 flush_ms=round(d[16] / d[15], 2) if d[15] else None)
    return dict(seconds=round(dt, 3), psi_pct=psi, devices=devices,
                units=byte_deltas(old[3], new[3]), slices=byte_deltas(old[4], new[4]),
                memory=new[5])


def byte_deltas(before, after):
    units = {}
    for name, counters in after.items():
        # A previously unseen cgroup may already have historical counters. Wait
        # for two readings instead of attributing them all to this interval.
        if name in before:
            r, w = (b - a for a, b in zip(before[name], counters))
            if min(r, w) >= 0 and (r or w):
                units[name] = {'read_bytes': r, 'write_bytes': w}
    return units


def probe(command):
    start = time.monotonic()
    try:
        result = subprocess.run(command, capture_output=True, timeout=2)
        status = 'ok' if result.returncode == 0 and result.stdout.strip() == b'1' else 'error'
    except subprocess.TimeoutExpired:
        status = 'timeout'
    return {'at': time.time(), 'ms': round(1000 * (time.monotonic() - start), 2), 'status': status}


def sync_probe(path):
    start = time.monotonic()
    try:
        # Overwrite one block in the existing StateDirectory on the monitored fs.
        fd = os.open(path, os.O_WRONLY | os.O_CREAT, 0o600)
        try:
            if os.write(fd, os.urandom(4096)) != 4096:
                raise OSError('short probe write')
            os.fdatasync(fd)
        finally:
            os.close(fd)
        status = 'ok'
    except OSError:
        status = 'error'
    return {'at': time.time(), 'ms': round(1000 * (time.monotonic() - start), 2), 'status': status}


def triggers(sample):
    reasons = []
    if sample['psi_pct']['full'] >= 5:
        reasons.append('io-pressure')
    for name, d in sample['devices'].items():
        if max(d['read_ms'] or 0, d['write_ms'] or 0) >= 250:
            reasons.append(name + '-latency')
    pg = sample.get('postgres')
    if pg and (pg['status'] != 'ok' or pg['ms'] >= 250):
        reasons.append('postgres')
    sync = sample.get('sync')
    if sync and (sync['status'] != 'ok' or sync['ms'] >= 250):
        reasons.append('durable-write')
    return reasons


def open_history(path):
    db = sqlite3.connect(path)
    db.execute('PRAGMA journal_mode=WAL')
    db.execute('PRAGMA synchronous=NORMAL')
    db.execute('CREATE TABLE IF NOT EXISTS samples (ts REAL NOT NULL, trigger TEXT NOT NULL, data TEXT NOT NULL)')
    db.execute('CREATE INDEX IF NOT EXISTS samples_time ON samples(ts)')
    return db


def flush(db, rows, now, prune):
    with db:
        for timestamp, reasons, payload in rows:
            db.execute('INSERT INTO samples (ts, trigger, data) VALUES (?, ?, ?)',
                       (timestamp, reasons, payload))
        if prune:
            db.execute('DELETE FROM samples WHERE ts < ?', (now - RETENTION,))
    rows.clear()


def main():
    try:
        device = Path('/').stat().st_dev
        disk_dev = (SYS / 'class/block/sda/dev').read_text().strip()
    except OSError as exc:
        raise SystemExit(f'Cannot identify Erdtree storage devices: {exc}') from exc
    root_dev = f'{os.major(device)}:{os.minor(device)}'
    stop = threading.Event()
    for sig in (signal.SIGINT, signal.SIGTERM):
        signal.signal(sig, lambda *_: stop.set())
    state = Path(os.environ['STATE_DIRECTORY'])
    db = open_history(state / 'history.sqlite')
    old = snapshot(root_dev, disk_dev)
    pending = []
    next_prune = next_probe = 0
    next_flush = time.monotonic() + 30
    future = sync_future = None
    next_sync = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        try:
            while not stop.wait(max(0, old[0] + INTERVAL - time.monotonic())):
                new = snapshot(root_dev, disk_dev)
                sample = interval(old, new)
                old = new
                if future and future.done():
                    sample['postgres'] = future.result()
                    future = None
                if future is None and new[0] >= next_probe:
                    future = pool.submit(probe, sys.argv[1:])
                    next_probe = new[0] + 10
                if sync_future and sync_future.done():
                    sample['sync'] = sync_future.result()
                    sync_future = None
                if sync_future is None and new[0] >= next_sync:
                    sync_future = pool.submit(sync_probe, state / 'probe.block')
                    next_sync = new[0] + 60
                wall = time.time()
                pending.append((wall, ','.join(triggers(sample)), json.dumps(sample, separators=(',', ':'))))
                if new[0] >= next_flush or new[0] >= next_prune:
                    prune = new[0] >= next_prune
                    flush(db, pending, wall, prune)
                    next_flush = new[0] + 30
                    if prune:
                        next_prune = new[0] + 3600
        finally:
            flush(db, pending, time.time(), False)
            db.close()


if __name__ == '__main__':
    main()
