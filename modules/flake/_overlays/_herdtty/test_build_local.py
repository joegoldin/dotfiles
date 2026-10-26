#!/usr/bin/env python3
import importlib.util
import io
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('build_local', Path(__file__).with_name('build-local.py'))
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class LocalBuildTests(unittest.TestCase):
    def test_build_passes_pinned_revision(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source, state = root / 'source', root / 'state'
            source.mkdir()
            state.mkdir()
            manifest = {'source': str(source), 'revision': 'b' * 40}

            def compile(*args, **kwargs):
                (kwargs['cwd'] / 'zig-out/releases/build.test').mkdir(parents=True)

            with patch.object(builder, 'run', side_effect=compile) as run, patch.object(builder, 'verify'):
                output = builder.build(source, state, 'nix', manifest)
            self.assertEqual(run.call_args.kwargs['env']['HERDTTY_BUILD_REVISION'], manifest['revision'])
            self.assertIn(manifest['revision'], (output / 'local-source.json').read_text())

    def test_rejects_invalid_revision_before_building(self):
        error = io.StringIO()
        with patch.object(builder.sys, 'argv', ['builder', '--source', '/missing', '--revision', 'unknown', '--identity', 'unused']), patch.object(builder.sys, 'stderr', error), patch.object(builder, 'run') as run:
            with self.assertRaises(SystemExit):
                builder.main()
        self.assertIn('--revision must be a full hexadecimal source commit', error.getvalue())
        run.assert_not_called()

    def test_identity_name_and_fingerprint(self):
        fingerprint = 'A' * 40
        identities = f'1) {fingerprint} "Apple Development: Test (TEAM)"'
        self.assertEqual(builder.identity_fingerprint('Apple Development: Test (TEAM)', identities), fingerprint)
        self.assertEqual(builder.identity_fingerprint(fingerprint.lower(), identities), fingerprint)
        with self.assertRaises(RuntimeError):
            builder.identity_fingerprint('missing', identities)
        with self.assertRaises(RuntimeError):
            builder.identity_fingerprint(fingerprint, identities + '\n' + identities)

    def test_refuses_running_apps(self):
        with patch.object(builder, 'run', return_value='PID COMM\n123 /Users/test/Applications/herdtty Terminal.app/Contents/MacOS/herdtty\n'):
            with self.assertRaisesRegex(RuntimeError, 'Close herdtty'):
                builder.idle()

    def fixture(self, root, existing):
        apps, staging, backup = (root / x for x in ('apps', 'staging', 'backup'))
        for p in (apps, staging, backup):
            p.mkdir()
        for name in builder.APPS:
            (staging / name / 'Contents').mkdir(parents=True)
            (staging / name / 'Contents/data').write_text('new')
            if name in existing:
                (apps / name / 'Contents').mkdir(parents=True)
                (apps / name / 'Contents/data').write_text('old')
        return apps, staging, backup

    @staticmethod
    def ditto(*args, **kwargs):
        assert args[0] == '/usr/bin/ditto'
        shutil.copytree(args[1], args[2])

    def test_install_preserves_outer_directory_and_backup(self):
        with tempfile.TemporaryDirectory() as directory:
            apps, staging, backup = self.fixture(Path(directory), builder.APPS)
            inodes = {n: (apps / n).stat().st_ino for n in builder.APPS}
            with patch.object(builder, 'idle'), patch.object(builder, 'run', side_effect=self.ditto), patch.object(builder, 'verify'):
                builder.install(staging, apps, backup, 'A' * 40)
            for name in builder.APPS:
                self.assertEqual((apps / name).stat().st_ino, inodes[name])
                self.assertEqual((apps / name / 'Contents/data').read_text(), 'new')
                self.assertEqual((backup / name / 'Contents/data').read_text(), 'old')

    def test_failure_rolls_back_both_existing_apps(self):
        self.check_rollback(list(builder.APPS))

    def test_failure_rolls_back_mixed_existing_and_new_apps(self):
        self.check_rollback(['herdtty.app'])

    def check_rollback(self, existing):
        with tempfile.TemporaryDirectory() as directory:
            apps, staging, backup = self.fixture(Path(directory), existing)
            with patch.object(builder, 'idle'), patch.object(builder, 'run', side_effect=self.ditto), patch.object(builder, 'verify', side_effect=[None, RuntimeError('bad signature')]):
                with self.assertRaisesRegex(RuntimeError, 'bad signature'):
                    builder.install(staging, apps, backup, 'A' * 40)
            for name in builder.APPS:
                if name in existing:
                    self.assertEqual((apps / name / 'Contents/data').read_text(), 'old')
                else:
                    self.assertFalse((apps / name).exists())

    def test_refuses_symlink_app_without_touching_it(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            apps, staging, backup = self.fixture(root, [])
            (apps / 'herdtty.app').symlink_to(staging / 'herdtty.app')
            with self.assertRaisesRegex(RuntimeError, 'linked'):
                builder.install(staging, apps, backup, 'A' * 40)
            self.assertTrue((apps / 'herdtty.app').is_symlink())

    def test_signs_nested_code_before_bundles(self):
        with tempfile.TemporaryDirectory() as directory:
            app = Path(directory) / 'herdtty.app'
            plugin = app / 'Contents/PlugIns/Dock.plugin'
            plugin.mkdir(parents=True)
            executable = plugin / 'dock'
            executable.write_bytes(bytes.fromhex('cffaedfe'))
            with patch.object(builder, 'run') as run:
                builder.sign(app, 'A' * 40)
            self.assertEqual([c.args[-1] for c in run.call_args_list], [executable, plugin, app])
            self.assertTrue(all('--deep' not in c.args for c in run.call_args_list))


if __name__ == '__main__':
    unittest.main()
