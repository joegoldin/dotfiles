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

The migration is **incremental and per-host**: the old `flake.nix` host
definitions were moved verbatim into `modules/flake/legacy-hosts.nix`, and
hosts move out of there one at a time. Both worlds coexist; every flake
output keeps its existing name (`just` targets and `nh` keep working
unchanged).

## State of this branch (scaffold)

Done:

- `flake.nix` is now an entry point only:
  `outputs = inputs: flake-parts.lib.mkFlake { inherit inputs; } (import-tree ./modules)`.
  All inputs preserved verbatim; added `flake-parts`, `import-tree`, `den`,
  `drowse`.
- `modules/flake/` carries the former flake outputs as flake-parts modules:
  `systems`, `packages`, `overlays`, `checks` + `devShells` (`dev-shell.nix`),
  `formatter`, and `legacy-hosts.nix` (all hosts except cloud-proxy,
  verbatim).
- **cloud-proxy is fully migrated** as the exemplar:
  - entity: `den.hosts.x86_64-linux.cloud-proxy.users.joe` —
    `modules/hosts/cloud-proxy/default.nix`
  - host aspect split across two merging files (`default.nix` system config,
    `services.nix` caddy/fail2ban)
  - `_disk-config.nix` / `_hardware-configuration.nix` moved alongside
    (underscore paths are invisible to import-tree; they are plain NixOS
    modules, imported explicitly by the aspect)
  - user aspect `modules/users/joe.nix` (OS account via
    `provides.to-hosts.nixos`, home-manager base, includes the shared feature
    aspects)
  - shared aspects: `nix-settings`, `hm-settings`, `git`, `fish`, `gh`,
    `gpg`, `starship`
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
  non-flake-parts files live (`modules/_lib/meta.nix`,
  `modules/home/_hm/*.nix`, `modules/hosts/*/_*.nix`).
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
  module arguments.

## Feature migration patterns

Three patterns, all demonstrated in the scaffold, ordered by finality:

- **A — moved** (`git`): the hm module moved to `modules/home/_hm/git.nix`;
  the aspect points at it (`den.aspects.git.homeManager = ./_hm/git.nix;`)
  and the legacy path `hosts/common/home/git.nix` became a one-line shim
  importing the new location. Legacy hosts unchanged, single source of
  truth. When the last legacy importer is gone, inline `_hm/git.nix` into
  the aspect and delete the shim.
- **B — pointed-at** (`gh`, `gpg`, `starship`, `fish`): the aspect
  references the legacy file in place
  (`den.aspects.gh.homeManager = ../../hosts/common/home/gh.nix;`). Zero
  churn; flip to pattern A whenever you touch the feature. If the legacy
  module expects a specialArg, supply it with `_module.args` (see
  `modules/home/fish.nix`, which provides `dotfiles-secrets`).
- **C — inlined** (`nix-settings`, `hm-settings`, cloud-proxy itself): the
  config was lifted into the aspect because the legacy copy was per-host
  boilerplate, not a shared file.

Rule of thumb: B to get a host migrated quickly, A when a feature is shared
with legacy hosts, C once nothing legacy references it.

## Target taxonomy

Where everything ends up (`hosts/` disappears at the end):

| Today | Target |
| --- | --- |
| `flake.nix` host blocks | `modules/hosts/<host>/…` (den entities + host aspects) |
| `hosts/common/home/fish/`, `starship`, `git`, `gh`, `gpg`, `1password`, `atuin` | `modules/home/<feature>.nix` (homeManager-only aspects) |
| `hosts/common/home/claude/`, `codex/`, `antigravity/`, `mcp.nix` | `modules/ai/<tool>.nix` |
| `hosts/common/home/bin/` (script library) | `modules/home/bin/` (one aspect; scripts stay data files under a `_scripts/` dir) |
| `hosts/common/home/packages/{default,shell-tools,workstation,linux-workstation}.nix` | `modules/home/packages/<set>.nix` — one aspect per package set; hosts/users include the sets they want |
| `hosts/common/system/attic*.nix` + `hosts/common/home/attic.nix` | `modules/services/attic.nix` — one cross-class aspect (nixos + darwin + homeManager halves together; the flagship den win) |
| `hosts/common/system/{gaming,howdy,oomd,earlyoom,microvm-host,1password-browsers,app-autostart,numtide-cache}.nix` | `modules/system/<feature>.nix` |
| `hosts/common/system/overlays/` | `modules/flake/overlays.nix` (inline the overlay set; already re-exported from there) |
| `hosts/common/system/pkgs/` | `modules/packages/` (perSystem packages; keep `pkgs/` sources as `_pkgs/` data files) |
| `hosts/nixos/*` (desktop) | `modules/hosts/joe-desktop/` + extracted features (`plasma`, `wallpaper`, `uxplay`, `vban`, `nut`, `desk-phone`, …) under `modules/desktop/` |
| `hosts/darwin/*` | `modules/hosts/macbook/` + `modules/darwin/` (homebrew, system defaults) |
| per-host `age.secrets` blocks in `flake.nix` | `modules/secrets/<secret>.nix` — aspect per secret (or secret group), included by the hosts/features that need it |
| `windows/`, `snippets/`, `assets/`, `secrets/`, `agent-skills/` | unchanged (not Nix modules / separate inputs) |

## Phase plan

Each phase is one PR-sized change, independently deployable; run the
verification protocol per phase.

1. **Scaffold (this branch).** flake-parts + import-tree + den; cloud-proxy
   migrated; legacy hosts verbatim. Risk: lowest for the five legacy hosts
   (same nixosSystem calls), moderate for cloud-proxy (new wiring).
2. **Servers: `racknerd-cloud-agent`, `oracle-cloud-bastion`.** Same shape
   as cloud-proxy. New aspects: `attic-server` (atticd + agenix secret),
   `pelican`. First agenix-on-den hosts: add `modules/secrets/` aspects
   (`age.secrets.*` + `age.identityPaths` in the host aspect). Entity name
   stays `oracle-cloud-bastion` while `hostName = "bastion"` via den's
   host option.
3. **Workstation features.** Extract the big shared home tree
   (`packages/*`, `claude`, `codex`, `zen`, `zed`, `ghostty`, `python`,
   `bin`, …) into aspects with pattern B, flipping to A opportunistically.
   `plasma-manager` / `nix-flatpak` sharedModules become part of a
   `plasma` / `flatpak` aspect's homeManager `imports`.
4. **`joe-desktop`, `office-pc`.** Host freeform metadata replaces the
   per-host overlay forks: e.g. `den.hosts.x86_64-linux.office-pc.rocm = true`
   and one parametric include
   (`{ host, ... }: { nixos.nixpkgs.overlays = …; }`) builds the right
   `unstable` overlay from it. lanzaboote, attic-post-build-hook, desk-phone
   become aspects.
5. **`joe-steamdeck`, `Joes-MacBook-Pro`.** Steamdeck: jovian aspect.
   Darwin: den's default darwin builder is `inputs.darwin.lib.darwinSystem`
   — either add `darwin.follows = "nix-darwin"` as an input alias or set
   `den.hosts.aarch64-darwin.Joes-MacBook-Pro.instantiate =
   inputs.nix-darwin.lib.darwinSystem`. nix-homebrew/virby/mac system
   settings become darwin-class aspects; cross-platform features (attic,
   fish, git, …) just gain their darwin halves in the same files.
6. **Endgame.** `office-pc-installer` moves from legacy-hosts.nix to its own
   flake-parts module (it is an artifact build, not an entity — keep it as
   plain `flake.nixosConfigurations.office-pc-installer`, or set
   `intoAttr` on a den host if you prefer). Delete
   `modules/flake/legacy-hosts.nix`, then `hosts/` entirely (flip remaining
   pattern-B aspects to A as their files move). Optional polish:
   [flake-file](https://github.com/vic/flake-file) so each module declares
   its own inputs and `flake.nix` is generated (`nix run .#write-flake`);
   den quirks for cross-cutting data (e.g. a `firewall` quirk where any
   aspect emits ports and one module folds them into
   `networking.firewall`).

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

This scaffold was written without a Nix evaluator (and without the
`secrets/`/`agent-skills/` submodules), so treat the branch as unevaluated
until you run, on any machine with this repo + submodules:

```bash
git submodule update --init
nix flake lock                      # locks flake-parts, import-tree, den, drowse
nix flake show                      # all 7 config outputs present, same names
nix flake check --no-build

# legacy hosts must be bit-identical to main (only paths moved):
for h in oracle-cloud-bastion racknerd-cloud-agent joe-desktop office-pc joe-steamdeck; do
  nix eval .#nixosConfigurations.$h.config.system.build.toplevel.drvPath
done
# run on main, run here, diff — expect identical drvPaths.
nix eval .#darwinConfigurations.Joes-MacBook-Pro.system.drvPath  # (on the Mac)

# cloud-proxy is rewired, so expect a *different* drvPath; compare contents:
nix build .#nixosConfigurations.cloud-proxy.config.system.build.toplevel -o result-new
git worktree add /tmp/dotfiles-main main && (cd /tmp/dotfiles-main && nix build .#nixosConfigurations.cloud-proxy.config.system.build.toplevel -o result-old)
nvd diff /tmp/dotfiles-main/result-old result-new   # or: nix store diff-closures
```

For cloud-proxy, eyeball the diff for: hostname, joe's uid/shell/ssh keys,
caddy vhosts (both domains), fail2ban jails, tailscale, grub/disko, fish +
atuin config, stateVersion 25.11. Then `just build-to-cloud-proxy` (build
only) before switching.

Known unknowns to watch on first eval — all four have one-line fixes:

- den is young and unpinned here; pin it after the first successful lock
  (`den.url = "github:denful/den?rev=…"`) like every other input.
- `hm-settings` sets `home-manager.useGlobalPkgs/useUserPackages` plainly;
  if den's home-manager battery also sets them you'll get a module
  conflict — resolve with `lib.mkForce` (or drop ours if den's defaults
  match).
- `home.username`/`home.homeDirectory` are `mkDefault` in
  `modules/users/joe.nix` in case den's battery sets them too.
- If den warns that the joe aspect's includes carry classes the user entity
  doesn't participate in, scope the includes per-class instead.

Rollback story: legacy hosts are untouched semantics — if anything is off,
`git revert` of this branch restores the old flake.nix world exactly.
