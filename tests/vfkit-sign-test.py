#!/usr/bin/env python3
"""Check rollback when LaunchServices rejects a freshly signed app."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

source = Path(__file__).resolve().parents[1] / 'modules/hosts/torrent/_vfkit-sign.sh'
with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    store = root / 'store'
    binary = store / 'Applications/vfkit.app/Contents/MacOS/vfkit'
    binary.parent.mkdir(parents=True)
    binary.write_text('#!' + shutil.which('bash') + '\nexit 0\n')
    binary.chmod(0o755)
    signer = store / 'share/vfkit/contrib/usb/sign.sh'
    signer.parent.mkdir(parents=True)
    signer.write_text('exit 0\n')
    profile = root / 'profile'
    profile.write_text('fixture')
    destination = root / 'vfkit.app'
    destination.mkdir()
    (destination / 'previous').write_text('keep this app')
    marker = root / 'vfkit.signed-build'
    marker.write_text('keep this stamp')
    script = root / 'sign.sh'
    script.write_text(source.read_text()
                      .replace('export PATH=/usr/bin:/bin:/usr/sbin:/sbin', ':')
                      .replace('profile_hash=$(shasum -a 256 "$profile" | cut -d \' \' -f1)', 'profile_hash=fixture')
                      .replace('/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister', shutil.which('false')))
    result = subprocess.run(['bash', str(script), str(store), str(profile), 'fixture', str(destination)], env=os.environ)
    assert result.returncode != 0, 'registration failure must propagate'
    assert (destination / 'previous').read_text() == 'keep this app'
    assert marker.read_text() == 'keep this stamp'
    assert not list(root.glob('.vfkit-sign.*')), 'staging directory leaked'
print('vfkit activation rollback passes')
