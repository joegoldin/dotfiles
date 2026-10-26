# Local macOS herdtty

On Darwin, `pkgs.herdtty` provides `herdtty-build-local` and launchers for the
locally installed apps. It does not download release ZIPs. Linux still uses the
normal Nix source derivation. `pkgs.herdtty-release` retains the optional signed,
notarized release package.

Home Manager's `herdttyLocalApps` activation builds the source pinned by the
`herdtty` flake input using local Xcode and that source's Nix development shell.
It then signs both apps with the same Apple Development identity used for Zen
and installs them under `~/Applications`. Compilation and keychain access happen
outside the Nix sandbox; `nix build` of the launcher package alone does not
compile the apps. No notarization or release publication happens here.

An unchanged source, helper recipe, architecture, identity and destination skip
compilation after verifying both installed signatures. Close both herdtty apps
before an update. Updates preserve the outer bundle directories, save backups
under `~/.local/state/herdtty/local/app-backups`, and roll back both apps if an
installation check fails. The helper does not change keychain settings, Dock
preferences, or live herdr servers. The subsequent declarative default-terminal
hook registers the installed terminal bundle.

To build, sign and install explicitly from a local Mac terminal:

```fish
nix shell "$HOME/dotfiles#darwinConfigurations.torrent.pkgs.herdtty" -c herdtty-build-local
```

To compile and verify without signing or installing, add `--build-only`. It
prints the prepared build directory. A later invocation with
`--build-directory /path/to/build` signs and installs that output only if its
source, architecture and helper recipe match. `--identity` can select another
available Apple Development or Developer ID certificate; `--force` rebuilds an
unchanged installation. Neither option bypasses signature verification.

Local Apple Development signing is not a substitute for Developer ID signing,
notarization and stapling when distributing an app. Keep the release workflow
separate.

Run the transaction and signing-order tests with:

```fish
python3 -B modules/flake/_overlays/_herdtty/test_build_local.py
```

The wrapper passes the pinned flake revision as `HERDTTY_BUILD_REVISION` for
source archives, which do not contain Git metadata. The build manifest includes
that revision, so prepared builds and unchanged-source checks cannot silently
reuse a different commit. New herdtty versions show its short hash in About;
changing this wrapper does not update the source pin or installed apps.
