# Dendritic migration

Rewriting this repo around three references:

- **[mightyiam/dendritic](https://github.com/mightyiam/dendritic)** — the
  pattern: every `.nix` file (except entry points) is a flake-parts module of
  one top-level configuration; features, not hosts, are the unit of
  organization.
- **[denful/den](https://github.com/denful/den)** — the engine: an
  aspect-oriented layer over the dendritic pattern. One *aspect* per feature
  carries its `nixos`, `darwin` and `homeManager` halves together; *entities*
  (`den.hosts.<system>.<name>.users.<user>`) select aspects and den generates
  `nixosConfigurations` / `darwinConfigurations` / `homeConfigurations` from
  them. Docs: <https://den.denful.dev>.
- **[figsoda/drowse](https://github.com/figsoda/drowse)** — the IFD
  replacement. Note: drowse is *not* a config-organization pattern; it is a
  dynamic-derivations library that evaluates Nix at **build** time
  (recursive-nix) instead of eval time, giving fine-grained caching without
  import-from-derivation or committed codegen. It plugs into this repo as a
  package-building tool, orthogonal to the den structure. See
  [drowse: replacing IFD](#drowse-replacing-ifd).

**All hosts are den entities** — there is no legacy `nixosSystem` call left;
`flake.nix` is a one-line entry point and den generates every configuration.
What remains incremental is the *feature* migration: the per-host module
trees under `hosts/` are still imported by their host aspects through a
compatibility bridge, and they dissolve into `modules/` aspects
feature-by-feature. Every flake output keeps its existing name (`just`
targets and `nh` keep working unchanged).

## State of this branch

- `flake.nix` is an entry point only:
  `outputs = inputs: flake-parts.lib.mkFlake { inherit inputs; } (import-tree ./modules)`.
  All inputs preserved verbatim; added `flake-parts`, `import-tree`, `den`,
  `drowse`.
- `modules/flake/` carries the former flake outputs as flake-parts modules:
  `systems`, `packages`, `overlays`, `checks` + `devShells`
  (`dev-shell.nix`), `formatter`.
- **Every host is a den entity** under `modules/hosts/`:

  | Entity (= flake output) | File | Depth |
  | --- | --- | --- |
  | `cloud-proxy` | `modules/hosts/cloud-proxy/` | fully migrated (no hosts/ tree left) |
  | `oracle-cloud-bastion` (hostName `bastion`) | `modules/hosts/oracle-cloud-bastion.nix` | bridged |
  | `racknerd-cloud-agent` | `modules/hosts/racknerd-cloud-agent.nix` | bridged |
  | `joe-desktop` | `modules/hosts/joe-desktop.nix` | bridged |
  | `office-pc` | `modules/hosts/office-pc/default.nix` | bridged |
  | `joe-steamdeck` | `modules/hosts/joe-steamdeck.nix` | bridged |
  | `Joes-MacBook-Pro` | `modules/hosts/macbook.nix` | bridged (darwin) |
  | `office-pc-installer` | `modules/hosts/office-pc/installer.nix` | artifact, not an entity |

  *Bridged* = the host aspect imports the legacy tree (`../../hosts/<dir>`)
  unchanged, plus the external modules (disko/agenix/jovian/…) and the
  inline agenix-secrets block the old flake.nix carried. Parity with the old
  `specialArgs` plumbing comes from two mechanisms, both the exact ones the
  old flake used:
  - OS eval: the entity overrides `instantiate`, wrapping
    `nixosSystem`/`darwinSystem` to merge
    `modules/_lib/legacy-args.nix` (verbatim `commonSpecialArgs`) into den's
    specialArgs;
  - hm eval: the host aspect sets `home-manager.extraSpecialArgs` to the
    same set, and `home-manager.users.joe` imports the legacy
    `home-manager.nix`.
- `cloud-proxy` shows the end state: entity + host aspect split across
  merging files, no specialArgs, no hosts/ tree.
- User aspect `modules/users/joe.nix`: OS account (`provides.to-hosts`,
  every leaf `mkDefault` so the not-yet-extracted host trees keep winning),
  hm base, and the shared feature aspects (`git`, `fish`, `gh`, `gpg`,
  `starship`). Those includes are safe on every host because each legacy hm
  tree already imports the same files — the module system dedups imports by
  path.
- Shared aspects: `nix-settings` (cloud-proxy only for now; bridged hosts
  carry their own copy inside their tree), `hm-settings`
  (useGlobalPkgs/useUserPackages/backupCommand, `os`-class so it serves
  darwin too — included by every host).
- drowse wired: input added; `den.aspects.dynamic-derivations`
  (`modules/nix/dynamic-derivations.nix`) is the opt-in switch for the
  experimental features.

Not done here (no nix in this sandbox, and `secrets/`/`agent-skills/`
submodules are not checked out): `flake.lock` update and any evaluation.
**Run the [verification protocol](#verification-protocol) before deploying
anything.**

## Mechanics in 30 seconds

- `import-tree ./modules` imports every `.nix` file under `modules/` as a
  flake-parts module. Paths containing `/_` are skipped — that's where
  non-flake-parts files live (`modules/_lib/{meta,legacy-args}.nix`,
  `modules/home/_hm/*.nix`, `modules/hosts/cloud-proxy/_*.nix`).
- A file contributes config by assigning options:
  `den.aspects.<name>.<class> = <module>` merges by name across files, so a
  feature can grow in place without a central imports list.
- Aspects compose via `includes = [ den.aspects.x den.batteries.y ]`;
  hosts push config to their users via `provides.to-users.<class>`, users
  push to their hosts via `provides.to-hosts.<class>`.
- `den.batteries.*` are stock aspects (`hostname`, `define-user`,
  `primary-user`, `user-shell`, `unfree`, …).
- Shared constants that used to ride in `specialArgs` (`username`,
  `useremail`) live in `modules/_lib/meta.nix`; `keys`/`domains` are imported
  from the `dotfiles-secrets` input where needed. New modules never need
  `specialArgs` — files close over `inputs`/`config` from their flake-parts
  module arguments. `modules/_lib/legacy-args.nix` exists only to feed the
  bridged hosts/ trees and dies with them.

## Feature migration patterns

Three patterns, all demonstrated, ordered by finality:

- **A — moved** (`git`): the hm module was moved to
  `modules/home/_hm/git.nix`; the aspect points at it
  (`den.aspects.git.homeManager = ./_hm/git.nix;`) and the legacy path
  `hosts/common/home/git.nix` became a one-line shim importing the new
  location. Bridged hosts unchanged, single source of truth. When the last
  legacy importer is gone, inline `_hm/git.nix` into the aspect and delete
  the shim.
- **B — pointed-at** (`gh`, `gpg`, `starship`, `fish`, and every bridged
  host tree): the aspect references the legacy file in place. Zero churn;
  flip to pattern A whenever you touch the feature. If the legacy module
  expects a specialArg, supply it with `_module.args` (see
  `modules/home/fish.nix`) or, for whole host trees, the legacy-args bridge.
- **C — inlined** (`nix-settings`, `hm-settings`, cloud-proxy): the config
  was lifted into the aspect because nothing legacy references it anymore.

Rule of thumb: B got every host migrated; A when a feature is shared with
bridged trees; C once nothing under hosts/ references it.

## Target taxonomy

Where the remaining `hosts/` content ends up (`hosts/` and
`_lib/legacy-args.nix` disappear at the end):

| Today | Target |
| --- | --- |
| `hosts/common/home/fish/`, `starship`, `gh`, `gpg`, `1password`, `attic` | `modules/home/<feature>.nix` (homeManager-only aspects; fish/gh/gpg/starship already pointed-at) |
| `hosts/common/home/claude/`, `codex/`, `antigravity/`, `mcp.nix` | `modules/ai/<tool>.nix` |
| `hosts/common/home/bin/` (script library) | `modules/home/bin/` (one aspect; scripts stay data files under a `_scripts/` dir) |
| `hosts/common/home/packages/{default,shell-tools,workstation,linux-workstation}.nix` | `modules/home/packages/<set>.nix` — one aspect per package set; hosts/users include the sets they want |
| `hosts/common/system/attic*.nix` + `hosts/common/home/attic.nix` | `modules/services/attic.nix` — one cross-class aspect (nixos + darwin + homeManager halves together; the flagship den win) |
| `hosts/common/system/{gaming,howdy,oomd,earlyoom,microvm-host,1password-browsers,app-autostart,numtide-cache}.nix` | `modules/system/<feature>.nix` |
| `hosts/common/system/overlays/` | `modules/flake/overlays.nix` (inline the overlay set; already re-exported from there) |
| `hosts/common/system/pkgs/` | `modules/packages/` (perSystem packages; keep `pkgs/` sources as `_pkgs/` data files) |
| `hosts/nixos/*` (desktop tree) | inlined into `modules/hosts/joe-desktop.nix` + extracted features (`plasma`, `wallpaper`, `uxplay`, `vban`, `nut`, `desk-phone`, …) under `modules/desktop/` |
| `hosts/oracle-cloud`, `hosts/racknerd-cloud`, `hosts/steamdeck`, `hosts/office-pc` | inlined into their `modules/hosts/` files (cloud-proxy-style), shared server bits → `modules/system/` |
| `hosts/darwin/*` | inlined into `modules/hosts/macbook.nix` + `modules/darwin/` (homebrew, system defaults) |
| per-host `age.secrets` blocks (now in `modules/hosts/*`) | `modules/secrets/<secret>.nix` — aspect per secret (or group), included by the hosts/features that need it |
| `windows/`, `snippets/`, `assets/`, `secrets/`, `agent-skills/` | unchanged (not Nix modules / separate inputs) |

## Phase plan

Phase 1 (this branch) made every host a den entity. The remaining phases
dissolve the bridged trees; each is PR-sized and independently deployable.
Run the verification protocol per phase.

2. **Servers deep-migration.** Inline `hosts/oracle-cloud`,
   `hosts/racknerd-cloud` into their host files cloud-proxy-style; extract
   `attic-server`, `pelican` aspects and `modules/secrets/`; have the
   servers include `den.aspects.nix-settings` instead of their own copies;
   drop their `instantiate` overrides + `extraSpecialArgs` once no file in
   the tree consumes specialArgs.
3. **Workstation features.** Extract the big shared home tree
   (`packages/*`, `claude`, `codex`, `zen`, `zed`, `ghostty`, `python`,
   `bin`, …) into aspects with pattern B, flipping to A opportunistically.
   `plasma-manager` / `nix-flatpak` sharedModules become part of a
   `plasma` / `flatpak` aspect's homeManager `imports`.
4. **`joe-desktop` / `office-pc` deep-migration.** Host freeform metadata
   replaces the per-host overlay forks: e.g.
   `den.hosts.x86_64-linux.office-pc.rocm = true` and one parametric include
   (`{ host, ... }: { nixos.nixpkgs.overlays = …; }`) builds the right
   `unstable` overlay from it. lanzaboote, attic-post-build-hook, desk-phone
   become aspects.
5. **`joe-steamdeck` / `Joes-MacBook-Pro` deep-migration.** Steamdeck:
   jovian aspect. Darwin: nix-homebrew/virby/mac system settings become
   darwin-class aspects; cross-platform features (attic, fish, git, …) gain
   their darwin halves in the same files. Consider
   `darwin.follows = "nix-darwin"` as an input alias so the explicit
   `instantiate` override can go.
6. **Endgame.** Delete `hosts/` and `modules/_lib/legacy-args.nix`; flip
   remaining pattern-B aspects to A as their files move. Optional polish:
   [flake-file](https://github.com/vic/flake-file) so each module declares
   its own inputs and `flake.nix` is generated (`nix run .#write-flake`);
   den quirks for cross-cutting data (e.g. a `firewall` quirk where any
   aspect emits ports and one module folds them into
   `networking.firewall`); den batteries (`define-user`, `primary-user`,
   `user-shell`) replacing the hand-rolled account config in
   `modules/users/joe.nix`.

## drowse: replacing IFD

Audit result: this repo is nearly IFD-free today. The only true
import-from-derivation is in the vendored `mkwindowsapp`
(`hosts/common/system/pkgs/mkwindowsapp/{default,test}.nix`):

```nix
${builtins.readFile (import ./filemap.nix { inherit writeScript rsync; })}
```

`filemap.nix` returns a `writeScript` derivation, and `builtins.readFile`
on its outPath forces a build during evaluation. Two fixes:

- **Plain (no drowse):** pass the script as a dependency instead of
  splicing its text: `fileMapScript = import ./filemap.nix { … };` then
  `''… ${fileMapScript} …''` (or `source ${fileMapScript}`) inside the
  builder. No experimental features needed; do this one regardless.
- **drowse-style (the general pattern, for when eval-time text generation
  is unavoidable):**

  ```nix
  let
    drowse = inputs.drowse.lib.${pkgs.stdenv.hostPlatform.system};
  in
  drowse.callPackage ./expensive-to-eval.nix { inherit pkgs; }
  ```

  `drowse.callPackage` defers evaluating the file to build time (a dynamic
  derivation), so the outer eval never blocks on a build. Same idea scales
  to `drowse.crate2nix` for Rust projects (Cargo.lock → per-crate
  derivations without IFD or committed codegen) and `drowse.instantiate`
  for arbitrary deferred `nix-instantiate` calls — useful for
  `custom-pypi-packages.nix`-style trees if you ever generate them from
  lockfiles instead of hand-pinning.

Enablement and caveats (why `den.aspects.dynamic-derivations` is opt-in,
not in `den.default`):

- Requires `ca-derivations` + `dynamic-derivations` + `recursive-nix` on
  the **building** machine (and any remote builder, e.g. virby on the Mac).
  These are genuinely experimental in upstream Nix.
- Content-addressed outputs interact with binary caches: attic must accept
  CA realisations for cached drowse-built packages to substitute. Test a
  push/pull against your attic instance before relying on it
  (substituting normal outputs is unaffected).
- Keep drowse-built packages out of `perSystem.packages` until CI/cache
  machines have the features enabled, or `nix flake check` will fail there.

Suggested rollout: include `den.aspects.dynamic-derivations` on
`joe-desktop` first, convert the mkwindowsapp splice, and only then
consider lockfile-driven uses.

## Verification protocol

This branch was written without a Nix evaluator (and without the
`secrets/`/`agent-skills/` submodules), so treat it as unevaluated until
you run, on any machine with this repo + submodules:

```bash
git submodule update --init
nix flake lock                      # locks flake-parts, import-tree, den, drowse
nix flake show                      # all 8 config outputs present, same names
nix flake check --no-build

# every host is rewired through den, so compare closures, not drvPaths:
git worktree add /tmp/dotfiles-main main
for h in cloud-proxy oracle-cloud-bastion racknerd-cloud-agent joe-desktop office-pc joe-steamdeck; do
  nix build .#nixosConfigurations.$h.config.system.build.toplevel -o result-new-$h
  (cd /tmp/dotfiles-main && nix build .#nixosConfigurations.$h.config.system.build.toplevel -o result-old-$h)
  nvd diff /tmp/dotfiles-main/result-old-$h result-new-$h   # or: nix store diff-closures
done
# on the Mac:
nix build .#darwinConfigurations.Joes-MacBook-Pro.system   # + same comparison
```

Expectation: bridged hosts should be functionally identical — same trees,
same specialArgs, same external modules. Diffs to eyeball per host:
hostname, joe's uid/shell/ssh keys, agenix secret set, hm activation
(fish/atuin/git), and on the bridged hosts that den newly touches, anything
den's home-manager battery adds. cloud-proxy is fully rewired: check
hostname, caddy vhosts (both domains), fail2ban jails, tailscale,
grub/disko, stateVersion 25.11. Then `just build` per machine before
switching.

Known unknowns to watch on first eval — each has a one-line fix:

- den is young and unpinned here; pin it after the first successful lock
  (`den.url = "github:denful/den?rev=…"`) like every other input.
- The `instantiate` override assumes den calls it with the same attrset
  `nixosSystem`/`darwinSystem` accept (that is den's documented override
  point — a raw `nixosSystem` can be dropped in). If den passes extra
  keys that `nixosSystem` rejects, filter them in the wrapper.
- `hm-settings` sets `home-manager.useGlobalPkgs/useUserPackages` plainly;
  if den's home-manager battery also sets them you'll get a module
  conflict — resolve with `lib.mkForce` (or drop ours if den's defaults
  match). Likewise `extraSpecialArgs` merges with whatever den's battery
  sets there.
- `home.username`/`home.homeDirectory` are `mkDefault` in
  `modules/users/joe.nix` in case den's battery sets them too.
- If den warns that the joe aspect's includes carry classes the user entity
  doesn't participate in, scope the includes per-class instead.

Rollback story: the hosts/ trees are untouched and `main` still has the old
flake.nix — `git revert` (or rebuilding from main) restores the old world
exactly.
