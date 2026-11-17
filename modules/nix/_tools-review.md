# Nix utility review

Reviewed 2026-11-17. No obvious malicious behavior found in the inspected
first-party source and packaging. This is a focused source review, not a
security audit, a full transitive dependency review, or a guarantee of safety.
Future package/input updates need fresh review. Versions and test results below
are a record of that review, not a live inventory or a new safety attestation.
For current package wiring, see [`tools.nix`](tools.nix); for commands, see the
[Justfile](../../Justfile).

## Sources at review time

| Tool | Version / revision | Source of pin |
| --- | --- | --- |
| nix-fast-build | 1.4.0 / `9c5bad875bba54351daa48a4119bfb9ba04e3e03` | Existing stable nixpkgs input |
| nix-update | 1.15.1 / `555c087e33284b7368ed110600f2dc3cce72843c` | Existing stable nixpkgs input |
| fast-nix-gc | 0.1.0 / `b4471ec56911541f72f7a7b9b8fee7f42183f21b` | Explicit source-only input in flake.nix |

The first two use nixpkgs' hash-checked release tarballs, Python/setuptools
packaging, and wrapped Nix dependencies. Neither declares third-party Python
runtime dependencies. fast-nix-gc is absent from both current nixpkgs pins;
its upstream `nix/package.nix` builds with our nixpkgs toolchain, Cargo.lock,
and a fixed hash for its pinned Harmonia Git dependency. Its upstream flake,
cache configuration, and service modules are not imported.

## Findings and limits

### nix-fast-build

Inspected `nix_fast_build/__init__.py`, its CLI defaults, subprocess construction,
source transfer, upload workers, result reporting, and packaging. It delegates
evaluation/building to Nix tools; no hidden telemetry or unsolicited upload
path was apparent. Cachix, Attic, niks3, copy-to and SSH builds are explicitly
selected features. Remote mode uses `--no-check-sigs` for some copies and can
fall back to fetching tools from nixpkgs or GitHub. Only use trusted remotes;
our recipes do not enable remote mode or uploads.

It is not a system activation tool or a substitute for flake-output validation.
`just check` retains `nix flake check --no-build` before using it to build checks.
Two evaluation workers and two concurrent builds avoid its CPU-count worker
default on small hosts; they are not a hard total memory limit.

### nix-update

Inspected CLI dispatch, package evaluation, version/hash replacement, HTTP/GitHub
fetching, subprocess helpers, dependency hash updates, and lockfile generation.
Its expected behavior includes editing source files and querying registries or
source hosts. GitHub support can read netrc credentials and, for release API
queries, `GITHUB_TOKEN`, including for enterprise-style endpoints. Only run it
on trusted definitions/URLs with appropriately scoped credentials.

Update scripts, dependency fetch scripts, and optional lockfile generation can
execute package-provided code outside a build sandbox. Builds and hash refreshes
also trust the package definitions. No unexpected exfiltration or persistence
was apparent, but it is not a safe way to inspect arbitrary untrusted packages.
Our recipe uses neither `--commit` nor `--use-update-script` nor
`--generate-lockfile`; review all resulting diffs before rebuilding. It now
returns failure if any requested update fails, while still trying the rest.

### fast-nix-gc

Inspected CLI validation, root discovery, GC locking/socket protocol, graph
loading, SQLite invalidation, deletion, configuration lookup, and packaging.
The program directly modifies the Nix database and recursively removes dead
store paths. It scans process state for runtime roots, coordinates with builders,
and can remount a read-only store writable. These are intended GC operations,
not evidence of a backdoor, but defects here have a much larger impact than in
a build frontend. The optimiser binary is included by upstream packaging; it
is not enabled or scheduled here.

Operational concerns:

- Upstream documents incomplete `keep-outputs` behavior for floating CA
  derivations on Nix <2.35. This configuration uses dynamic derivations.
- [Open upstream PR #91](https://github.com/Mic92/fast-nix-gc/pull/91) addresses
  stale BuildTraceV3 realisation rows on Nix >=2.35. The reviewed main revision
  does not include that fix. The local Nix at review time was 2.34.9.
- Vacuuming can grow the SQLite WAL significantly while concurrent readers
  hold snapshots. The recipes pass `--no-vacuum`.
- `--dry-run` is not completely read-only: root discovery may remove stale
  auto-root links, it takes the GC lock/serves the local GC socket, and database
  opening can fall back from read-only to read-write mode.

Installed for explicit use, **not adopted as the default collector**. No system
GC services or timers were changed. `just nix-gc` retains its existing retention
policy and standard collector. `just nix-gc-fast` previews; explicit
`just nix-gc-fast collect` collects without deleting profile generations. No
live-store GC was run during this review.

## Coverage and verification

`den.aspects.nix-tools` is included by the joe user aspect, rather than the
workstation-heavy CLI package list. Evaluated package inclusion for all 11
managed host homes: dectus, elphael, erdtree, farum-azula, malenia, melina,
rennala, scarab, siofra, torrent, and volcano-manor. The installer ISO has no
Home Manager user profile.

Observed locally on x86_64-linux:

- All three package outputs realised successfully. fast-nix-gc built from
  source and its packaged Rust test suite passed.
- All four installed binaries (including fast-nix-optimise) accepted `--help`.
- Real nix-fast-build built two disposable checks; a deliberately failing
  derivation caused the Justfile recipe to fail.
- Real nix-update changed a disposable package from 1.0.0 to 1.1.0.
- A synthetic 10-path GC store with two roots reported eight dead paths in
  preview; all ten disk entries and database rows remained afterwards.
- Nine isolated recipe tests passed: `python3 modules/nix/_tests/test_tools.py`.
  These use mocked tools, never sudo or the live store.
- Changed Nix files passed nixfmt, statix, and active LSP diagnostics.

The first disposable build fixture failed because an unrelated `/tmp/.git`
caused Nix to misidentify its repository. Moving the fixture to `/var/tmp`
resolved that; its explicit store-path import also required `--impure`.
These setup failures were not passing tests.

No full system rebuild, activation, deployment, live-store GC, or native
Darwin/aarch64 execution was performed. Profile evaluation is not a native
build test. Apply the configuration through the usual reviewed rebuild flow
before expecting the commands on each host's PATH.
