# Reading Erdtree's stall history

`erdtree-stall-recorder.service` keeps **eight days** of continuous samples at
`/var/lib/erdtree-stall-recorder/history.sqlite`. It starts on boot and resumes
the same database after a restart. Every two seconds it samples host I/O PSI,
root mapper and PERC virtual disk counters, and physical-device byte deltas for
active direct children of `system.slice` (services and slices). Every ten seconds
a separate worker times a local PostgreSQL connection and `SELECT 1`, with a
two-second timeout. It uses peer auth, reads no application data, and does not
query the RAID controller or collect process arguments.

Run on Erdtree (use `nix shell nixpkgs#sqlite -c sqlite3` if needed):

```fish
systemctl status erdtree-stall-recorder
sudo sqlite3 -readonly -header -column /var/lib/erdtree-stall-recorder/history.sqlite "SELECT datetime(min(ts),'unixepoch') AS first_utc, datetime(max(ts),'unixepoch') AS last_utc, count(*) AS samples FROM samples;"
sudo sqlite3 -readonly -header -column /var/lib/erdtree-stall-recorder/history.sqlite "SELECT datetime(ts,'unixepoch') AS utc, trigger, json_extract(data,'$.psi_pct.full') AS full_pct, json_extract(data,'$.devices.root.write_ms') AS root_write_ms, json_extract(data,'$.postgres.ms') AS pg_ms FROM samples WHERE ts >= unixepoch('now','-1 day') AND trigger != '' ORDER BY ts DESC LIMIT 30;"
```

To see the minute before and after a hit, substitute its UTC timestamp:

```fish
sudo sqlite3 -readonly -json /var/lib/erdtree-stall-recorder/history.sqlite "SELECT datetime(ts,'unixepoch') AS utc, trigger, json(data) AS sample FROM samples WHERE ts BETWEEN unixepoch('2026-11-19 20:48:39')-60 AND unixepoch('2026-11-19 20:48:39')+60 ORDER BY ts;"
```

A flag means interval full PSI ≥5%, either device's mean read/write latency
≥250 ms, or a slow (≥250 ms) or unsuccessful PostgreSQL probe. Read the flags
together: pacing a Nix writer can inflate root latency without disrupting the
rest of the host. `read_ms` and `write_ms` are means over completed requests,
not percentiles; `null` means no completions. `queue` is the average number of
outstanding requests. `units` contains nonzero byte deltas, not rates; divide
by `seconds` for rates. Do not add the two device layers' throughput together.
`postgres.ms` includes launching the client; the probe has its own completion
timestamp and is absent between probes. It is not a durable-write benchmark.

SQLite batches inserts about every 30 seconds and prunes hourly. Unflagged
samples are retained too. At two-second cadence eight days is about 346,000
rows. SQLite reuses expired space rather than vacuuming under load. The first
week fills progressively; downtime leaves gaps, and an abrupt crash can lose
the latest unflushed batch. No storage limits or scheduler settings are changed.

Newer samples also include `devices.disk.flushes` and `flush_total_ms` (interval
counters), `flush_ms` (mean per completed flush, null if none), and `memory`
(`dirty_bytes` and `writeback_bytes` at sample time). `slices` shows byte deltas
for direct children of the root cgroup, including `system.slice`. Compare these
with whole-disk bytes; **do not add** `slices` to `units` (their scopes overlap).

Once per minute a separate worker overwrites and `fdatasync`s one 4 KiB block
beside the database. `sync.ms` measures open, write and sync together; a failure
or latency ≥250 ms is marked `durable-write`. At most one sync probe can be in
flight; a stuck sync does not queue another, block kernel sampling, or delay the
PostgreSQL probe. Its latency is recorded on completion. This measures the
filesystem's durability acknowledgement, not controller power-loss protection.
Older rows remain readable and lack the new fields.
