#!/usr/bin/env python3
"""Build pinned herdtty source with Xcode, then locally sign and install both apps."""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import platform
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile

APPS = {'herdtty.app': 'dev.herdtty', 'herdtty Terminal.app': 'dev.herdtty.terminal'}
MACHO = {bytes.fromhex(x) for x in ('cffaedfe', 'feedfacf', 'cafebabe', 'bebafeca', 'cafebabf', 'bfbafeca')}


def run(*args, capture=False, **kwargs):
    return subprocess.run([str(a) for a in args], check=True, text=True,
                          stdout=subprocess.PIPE if capture else None, **kwargs).stdout


def identity_fingerprint(requested, identities):
    matches = [fingerprint.upper() for fingerprint, name in
               re.findall(r'\b([0-9A-Fa-f]{40})\s+"([^"]+)"', identities)
               if (requested.upper() == fingerprint.upper() or requested == name)
               and name.startswith(('Apple Development:', 'Developer ID Application:'))]
    if len(matches) != 1:
        raise RuntimeError('Signing identity must match exactly one available Apple Development or Developer ID identity.')
    return matches[0]


def verify(app, identifier, identity=None):
    with (app / 'Contents/Info.plist').open('rb') as f:
        info = plistlib.load(f)
    if info.get('CFBundleIdentifier') != identifier or info.get('CFBundleExecutable') != 'herdtty':
        raise RuntimeError(f'Unexpected bundle identity: {app}')
    run('/usr/bin/lipo', app / 'Contents/MacOS/herdtty', '-verify_arch', platform.machine())
    run('/usr/bin/codesign', '--verify', '--deep', '--strict', app)
    if identity:
        run('/usr/bin/codesign', '--verify', '-R',
            f'=anchor apple generic and certificate leaf = H"{identity}"', app)


def sign(app, identity):
    code, containers = [], [app]
    for path in app.rglob('*'):
        if path.is_symlink():
            continue
        if path.is_dir() and path.suffix in ('.app', '.framework', '.xpc', '.appex', '.plugin', '.bundle'):
            containers.append(path)
        elif path.is_file():
            with path.open('rb') as f:
                if f.read(4) in MACHO:
                    code.append(path)
    # Sign nested code explicitly before its containers, not with --deep.
    for group in (code, containers):
        for path in sorted(group, key=lambda p: (-len(p.parts), str(p))):
            run('/usr/bin/codesign', '--force', '--sign', identity, '--timestamp=none',
                '--options', 'runtime', '--preserve-metadata=entitlements', path)


def idle():
    processes = run('/bin/ps', '-axo', 'pid,comm', capture=True)
    for line in processes.splitlines()[1:]:
        fields = line.strip().split(None, 1)
        if len(fields) == 2 and Path(fields[1]).name == 'herdtty':
            raise RuntimeError('Close herdtty and herdtty Terminal normally before updating their installed apps.')


def install(staging, applications, backup, identity):
    changed = []
    for name in APPS:
        target = applications / name
        if target.is_symlink() or (target.exists() and not (target / 'Contents').is_dir()):
            raise RuntimeError(f'Refusing to replace a linked or unexpected app: {target}')
        if target.exists():
            run('/usr/bin/ditto', target, backup / name)
    idle()
    try:
        for name, identifier in APPS.items():
            target = applications / name
            existed = target.exists()
            if existed:
                # Preserve the outer directory so Dock bookmarks don't follow backups.
                os.rename(target / 'Contents', backup / (name + '.original-contents'))
                changed.append((name, True))
                os.rename(staging / name / 'Contents', target / 'Contents')
            else:
                os.rename(staging / name, target)
                changed.append((name, False))
            verify(target, identifier, identity)
    except BaseException:
        for name, existed in reversed(changed):
            target = applications / name
            if existed:
                if (target / 'Contents').exists():
                    os.rename(target / 'Contents', staging / (name + '.failed-contents'))
                os.rename(backup / (name + '.original-contents'), target / 'Contents')
            else:
                os.rename(target, staging / name)
        raise


def build(source, state, nix, manifest):
    root = Path(tempfile.mkdtemp(prefix='source-build.', dir=state))
    checkout = root / 'source'
    shutil.copytree(source, checkout, symlinks=True)
    for directory, _, files in os.walk(checkout):
        Path(directory).chmod(Path(directory).stat().st_mode | 0o700)
        for name in files:
            path = Path(directory) / name
            if not path.is_symlink():
                path.chmod(path.stat().st_mode | 0o200)
    run(nix, 'develop', '--no-write-lock-file', f'path:{checkout}#default',
        '-c', 'bash', 'tools/build-herdtty-macos', 'native', cwd=checkout,
        env=dict(os.environ, HERDTTY_BUILD_REVISION=manifest['revision']))
    outputs = list((checkout / 'zig-out/releases').glob('build.*'))
    if len(outputs) != 1:
        raise RuntimeError('Expected one fresh native build output.')
    output = outputs[0]
    for name, identifier in APPS.items():
        verify(output / name, identifier)
    (output / 'local-source.json').write_text(json.dumps(manifest, indent=2) + '\n')
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', required=True, type=Path)
    parser.add_argument('--revision', required=True, help='Full pinned source commit')
    parser.add_argument('--nix', default='nix')
    parser.add_argument('--identity', required=True)
    parser.add_argument('--build-only', action='store_true', help='Compile and verify without signing or installing')
    parser.add_argument('--build-directory', type=Path, help='Sign/install a matching previously prepared build')
    parser.add_argument('--force', action='store_true')
    parser.add_argument('--state-directory', type=Path, default=Path.home() / '.local/state/herdtty/local')
    parser.add_argument('--applications-directory', type=Path, default=Path.home() / 'Applications')
    args = parser.parse_args()
    if not re.fullmatch(r'[0-9a-f]{40}|[0-9a-f]{64}', args.revision):
        parser.error('--revision must be a full hexadecimal source commit')
    if sys.platform != 'darwin':
        parser.error('Requires macOS, Xcode and a local signing identity.')
    source = args.source.resolve(strict=True)
    state = args.state_directory.expanduser().resolve()
    applications = args.applications_directory.expanduser().resolve()
    state.mkdir(parents=True, exist_ok=True, mode=0o700)
    manifest = {'source': str(source), 'revision': args.revision, 'architecture': platform.machine(),
                'recipe': hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    with (state / 'build.lock').open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError('Another herdtty source build/install is running.') from None
        identity = None
        if not args.build_only:
            identity = identity_fingerprint(args.identity, run('/usr/bin/security', 'find-identity', '-v', '-p', 'codesigning', capture=True))
        stamp = dict(manifest, identity=identity, applications=str(applications))
        marker = state / 'installed.json'
        if (not args.build_only and not args.force and marker.exists()
                and all((applications / name).is_dir() for name in APPS)):
            if json.loads(marker.read_text()) == stamp:
                for name, identifier in APPS.items():
                    verify(applications / name, identifier, identity)
                print('Pinned source and signing recipe unchanged; installed apps verified.')
                return
        if not args.build_only:
            idle()
        output = args.build_directory
        if output:
            if json.loads((output / 'local-source.json').read_text()) != manifest:
                raise RuntimeError('Prepared build does not match the pinned source, architecture and recipe.')
            for name, identifier in APPS.items():
                verify(output / name, identifier)
        else:
            output = build(source, state, args.nix, manifest)
        print('Prepared source build:', output, flush=True)
        if args.build_only:
            return
        applications.mkdir(parents=True, exist_ok=True)
        staging = Path(tempfile.mkdtemp(prefix='.herdtty-local.', dir=applications))
        for name, identifier in APPS.items():
            run('/usr/bin/ditto', output / name, staging / name)
            sign(staging / name, identity)
            verify(staging / name, identifier, identity)
        backups = state / 'app-backups'
        backups.mkdir(exist_ok=True)
        backup = Path(tempfile.mkdtemp(prefix='before-local.', dir=backups))
        install(staging, applications, backup, identity)
        temporary = marker.with_suffix('.tmp')
        temporary.write_text(json.dumps(stamp, indent=2) + '\n')
        temporary.replace(marker)
        print('Installed both locally signed source-built apps. Backups:', backup)
        print('Local signing only: not notarized or suitable as a distributed release.')


if __name__ == '__main__':
    main()
