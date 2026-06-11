# Dendritic migration

This repo is organized around three references:

- **[mightyiam/dendritic](https://github.com/mightyiam/dendritic)** — the
  pattern: every `.nix` file (except entry points and `_`-prefixed paths) is
  a flake-parts module of one top-level configuration.
- **[denful/den](https://github.com/denful/den)** — the engine: aspects
  carry a feature's `nixos`/`darwin`/`homeManager` halves together; entities
  (`den.hosts.<system>.<name>.users.<user>`) select aspects and den
  generates all `nixosConfigurations`/`darwinConfigurations`. Docs:
  <https://den.denful.dev>.
- **[figsoda/drowse](https://github.com/figsoda/drowse)** — the IFD
  replacement: a dynamic-derivations library (build-time Nix eval via
  recursive-nix), wired as an opt-in aspect. See
  [drowse](#drowse-replacing-ifd).

**The migration is complete**: `hosts/` is gone, there are no specialArgs,
no per-host `nixosSystem` calls, and `flake.nix` is a one-line entry point.
Every flake output keeps its pre-migration name, so `just`/`nh` workflows
are unchanged.

## Architecture

```
flake.nix                  inputs + mkFlake (import-tree ./modules) — nothing else
modules/
  _lib/meta.nix            identity constants (username, email)
  flake/                   flake-level outputs (one file per output)
    den.nix                den flakeModule + schema + stateVersion defaults
    systems.nix, formatter.nix, packages.nix, overlays.nix, dev-shell.nix
    _pkgs/                 custom package sources (was hosts/common/system/pkgs)
    _overlays/             overlay definitions (was hosts/common/system/overlays)
  nix/
    settings.nix           den.aspects.nix-settings (registry pinning, gc, …)
    module-args.nix        _module.args shim (see below)
    dynamic-derivations.nix  opt-in drowse experimental-features aspect
  home/
    git.nix, fish.nix, gh.nix, gpg.nix, starship.nix, hm-settings.nix
                           feature aspects (thin pointers into _hm/)
    _hm/                   the entire shared home tree (was hosts/common/home):
                           fish/, packages/, claude/, codex/, antigravity/,
                           zen/, bin/, python/, mouse-actions/, default.nix
                           (the shared baseline), 30+ single-feature modules
  system/_sys/             shared system modules (was hosts/common/system):
                           attic, attic-post-build-hook, numtide-cache,
                           gaming, howdy, microvm-host, oomd, earlyoom,
                           1password-browsers, app-autostart, streamcontroller
  _data/                   non-module data: dotconfig/, dotdocker/, fonts/,
                           microvm/ (profiles, module-gen.py, test-data)
  users/joe.nix            user aspect: account defaults (mkDefault), hm base,
                           includes the five global feature aspects
  hosts/<host>/            one directory per entity:
    default.nix            den.hosts entity + host aspect (imports, overlays,
                           agenix secrets, hm sharedModules, provides)
    _configuration.nix …   host-specific modules ("_" = import-tree-invisible)
    _home-manager.nix      the host's home tree, wired via
                           provides.to-users.homeManager
```

Hosts: `cloud-proxy` (fully aspect-native exemplar), `oracle-cloud-bastion`
(hostName `bastion`), `racknerd-cloud-agent`, `joe-desktop`, `office-pc`
(+ `office-pc-installer` as a plain artifact output in `installer.nix`),
`joe-steamdeck`, `Joes-MacBook-Pro` (darwin; explicit
`instantiate = inputs.nix-darwin.lib.darwinSystem` because den's default
expects an input literally named `darwin`).

## How the pieces interact

- **import-tree** loads every `.nix` under `modules/` as a flake-parts
  module; paths containing `/_` are skipped — that's where plain
  NixOS/home-manager modules, package sources, and data live.
- **Aspect merging**: `den.aspects.<name>.<class>` assignments merge by
  name across files (see `modules/hosts/cloud-proxy/{default,services}.nix`
  — one aspect, two files).
- **Host → users**: each host pushes its home environment to its users via
  `provides.to-users.homeManager` (imports `./_home-manager.nix` plus the
  flake-input hm modules: audiomemo, attic-client, agent-skills).
- **User → hosts**: `modules/users/joe.nix` provides the OS account via
  `provides.to-hosts.nixos`, all values `mkDefault` so per-host
  `_configuration.nix` definitions win where they exist.
- **The module-args shim** (`modules/nix/module-args.nix`): the moved
  modules still take `username`, `keys`, `inputs`, `dotfiles-secrets`,
  `commonOverlays`, `stateVersion`, `homeDirectory`, … as module arguments.
  den.default supplies all of them through `_module.args` (the standard
  module-system mechanism) for the nixos, darwin and homeManager classes;
  each host sets its own `_module.args.hostname`. This replaces the old
  `commonSpecialArgs` exactly — all consumption is body-level, which is
  what `_module.args` supports. Shrink it by rewriting modules to close
  over `inputs`/`meta` directly, then drop keys from the shim.

## drowse: replacing IFD

The repo is nearly IFD-free. The one true import-from-derivation is the
vendored mkwindowsapp (`modules/flake/_pkgs/mkwindowsapp/{default,test}.nix`):

```nix
${builtins.readFile (import ./filemap.nix { inherit writeScript rsync; })}
```

Fixes, in order of preference:

- **Plain:** stop splicing the script's text at eval time — reference the
  derivation (`source ${import ./filemap.nix { … }}`) inside the builder.
- **drowse:** for cases where eval-time generation is genuinely needed,
  `inputs.drowse.lib.${system}.callPackage ./file.nix { }` defers the
  evaluation to build time (dynamic derivation). `drowse.crate2nix` does
  the same for Rust (Cargo.lock → per-crate caching without IFD or
  committed codegen); `drowse.instantiate` for arbitrary deferred evals —
  a future option for lockfile-driven `_hm/python/custom-pypi-packages.nix`.

`den.aspects.dynamic-derivations` (modules/nix/dynamic-derivations.nix)
enables the required experimental features (`ca-derivations`,
`dynamic-derivations`, `recursive-nix`) on hosts that should *build*
drowse packages. Opt-in on purpose:

- The features are experimental upstream; remote builders (virby on the
  Mac) need them too.
- CA outputs require attic to accept CA realisations — test push/pull
  before relying on the cache for drowse-built packages.
- Keep drowse-built packages out of `perSystem.packages` until CI/cache
  machines have the features.

Rollout: include the aspect on `joe-desktop`, convert mkwindowsapp, then
evaluate lockfile-driven uses.

## Verification protocol

This migration was authored without a Nix evaluator and without the
`secrets/`/`agent-skills/` submodules. Every file was parse-checked and
every relative path mechanically verified, but **nothing has been
evaluated**. On a machine with the repo + submodules:

```bash
git submodule update --init
nix flake lock              # locks flake-parts, import-tree, den, drowse
nix flake show              # expect all 8 outputs under their old names
nix flake check --no-build

git worktree add /tmp/dotfiles-main main
for h in cloud-proxy oracle-cloud-bastion racknerd-cloud-agent joe-desktop office-pc joe-steamdeck; do
  nix build .#nixosConfigurations.$h.config.system.build.toplevel -o result-new-$h
  (cd /tmp/dotfiles-main && nix build .#nixosConfigurations.$h.config.system.build.toplevel -o result-old-$h)
  nvd diff /tmp/dotfiles-main/result-old-$h result-new-$h
done
# on the Mac: nix build .#darwinConfigurations.Joes-MacBook-Pro.system + same diff
python3 modules/_data/microvm/module-gen-test.py   # generator paths moved
```

Closures should be functionally identical: the same module files are
evaluated (at new paths) with the same argument values (via _module.args
instead of specialArgs). Eyeball per host: hostname, joe's account
(uid/shell/keys/groups), agenix secret set, hm activation (fish/atuin/zen/
plasma), and per-host overlay effects (`pkgs.unstable.*`, ROCm on
office-pc). Diff drivers worth knowing:

- den adds its own plumbing modules (hm battery) — config-identical, may
  reorder nothing user-visible.
- den is unpinned; pin it after first lock (`?rev=`).
- `hm-settings` sets useGlobalPkgs/useUserPackages/backupCommand plainly;
  if den's hm battery also sets one, eval errors — resolve with mkForce.
- If den itself passes `inputs` (or others) via specialArgs, specialArgs
  win over `_module.args`; values are identical either way.
- The joe aspect's `provides.to-hosts` and feature includes dedup against
  the host trees by path; a "defined twice" error there means a battery
  collision — check `den.batteries.os-user` interplay.

Rollback: `main` still has the old world; `git revert`/rebuild from main
restores it exactly.

## Follow-up cleanups (optional, post-verification)

1. Dedup the nix/nixpkgs boilerplate in `modules/hosts/*/_configuration.nix`
   into `den.aspects.nix-settings` (deltas: steamdeck 14d gc +
   auto-optimise, office-pc cores=20, macbook max-jobs/cores + extra
   platforms).
2. Promote heavily-shared `_hm` modules to first-class aspects (zen, zed,
   ghostty, plasma, claude/codex/antigravity under `modules/ai/`) and have
   host `_home-manager.nix` trees include aspects instead of paths.
3. Make `modules/services/attic.nix` the flagship cross-class aspect
   (merge `system/_sys/attic.nix` + `_hm/attic.nix` + post-build-hook).
4. Shrink `modules/nix/module-args.nix` to nothing; then delete it.
5. Host freeform metadata for the GPU overlay forks
   (`den.hosts.….office-pc.rocm = true` + one parametric include).
6. [flake-file](https://github.com/vic/flake-file): per-module input
   declarations, generated flake.nix (`nix run .#write-flake`).
7. den quirks for cross-cutting data (firewall ports, secret declarations);
   den batteries (`define-user`, `primary-user`, `user-shell`) replacing
   the hand-rolled account config in `modules/users/joe.nix`.
