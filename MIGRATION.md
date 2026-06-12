# Dendritic / den architecture

This repo is fully migrated to the dendritic pattern with den as the engine.
References: [mightyiam/dendritic](https://github.com/mightyiam/dendritic)
(the pattern), [denful/den](https://github.com/denful/den) (aspects +
entities; docs at <https://den.denful.dev>),
[figsoda/drowse](https://github.com/figsoda/drowse) (dynamic derivations —
the IFD replacement, wired as `den.aspects.dynamic-derivations`).

**There is no migration work remaining.** No `hosts/` tree, no specialArgs,
no `_module.args` shim, no legacy `nixosSystem` calls, no transitional
pointer files. Every flake output keeps its pre-migration name.

## Layout

```
flake.nix                 inputs + mkFlake (import-tree ./modules) — nothing else
modules/
  _lib/meta.nix           identity constants (username, email)
  flake/                  flake-level outputs: den.nix (schema/batteries/
                          defaults), systems, packages, overlays, formatter,
                          dev-shell; _pkgs/ + _overlays/ (sources)
  nix/                    nix-settings aspect (os + nixos halves),
                          dynamic-derivations aspect (drowse, opt-in)
  services/               attic.nix (cross-class: os + homeManager),
                          attic-post-build-hook.nix
  system/                 one aspect per system feature: gaming, howdy,
                          oomd, earlyoom, numtide-cache, app-autostart,
                          1password-browsers, microvm-host
  home/                   one aspect per home feature: fish/, git, gh, gpg,
                          starship, 1password, zed, zen/, ghostty/, plasma,
                          default-apps, notify, mouse-actions, bin/, cargo,
                          baseline (the shared bundle), hm-settings,
                          packages/ (cli/shell-tools/workstation/
                          linux-workstation/audiomemo)
  ai/                     claude, codex, antigravity, mcp aspects (each
                          carries its agent-skills hm module)
  users/joe.nix           account (provides.to-hosts for nixos AND darwin),
                          hm base, universal features (git/fish/gh/gpg/
                          starship)
  hosts/<entity>/         default.nix (entity + includes + secrets) and
                          sibling aspect files merging into the host aspect:
                          system.nix, machine.nix, home.nix, plus
                          host-specific concerns (wallpaper, mounts, vban,
                          nut, jovian, homebrew, …)
  _data/                  dotconfig, fonts, microvm (generator + fish-guest
                          + common-guest), dotdocker
```

Key mechanics:

- `den.schema.host.includes` wires three things into every host:
  `den.batteries.hostname` (networking.hostName from the entity),
  `den.batteries.host-aspects` (a host aspect's `homeManager` blocks are
  projected onto its users — this is how hosts select home features), and
  `den.aspects.hm-settings` (useGlobalPkgs/backupCommand).
- Underscored paths are import-tree-invisible by design and permanent:
  hardware/disk configs, package sources (`flake/_pkgs`), overlays, data,
  payload files referenced by their aspect (fish config parts, plasma
  panels, the bin script library), and `_lib/meta.nix`.
- `modules/home/bin/_module.nix` stays a standalone hm module because
  microVM guests import it by path at runtime (fish-guest/common-guest),
  outside den.

## Verification record (2026-06-11)

- All 8 configurations evaluate: 6 × NixOS + installer ISO + darwin
  (darwin evaluates to the same pre-existing agent-skills IFD limit as
  main when evaluated from Linux; targeted option evals confirm wiring —
  full build happens on the Mac).
- Eval-level config parity vs main for all 6 NixOS hosts (hostname, user,
  secrets, system+home package sets, ssh/gc/substituters): **identical**
  except `extraGroups` ordering (same set).
- Closure-level (nvd): cloud-proxy old-vs-new and joe-desktop vs the
  running system — **zero package changes** (only the +4 repo source
  paths from moved files).
- `nix flake show` evaluates every package output (the pre-existing
  `mkWindowsApp` makeBinPath eval bug is fixed).
- `modules/_data/microvm/module-gen-test.py` passes (generator emits the
  new fish-guest/common-guest paths).

Deliberate semantic deltas (the only ones):

- joe-desktop now includes `den.aspects.dynamic-derivations`: its
  nix.settings gains `ca-derivations`, `dynamic-derivations`,
  `recursive-nix` — the drowse enablement. Remove the include to revert.
- steamdeck's nixpkgs config gains `allowUnsupportedSystem = true`
  (unified via nix-settings; eval-permissiveness only).
- mkwindowsapp: the eval-time `builtins.readFile` of the filemap script
  (true IFD) is now a runtime `source` of the same derivation.
- Dead files removed: `hosts/oracle-cloud/attic.nix` (never imported).
  `modules/home/cargo.nix` is kept but (as before) included by nothing.

## drowse usage

`inputs.drowse.lib.${system}.callPackage ./file.nix { }` evaluates a file
at build time (dynamic derivation) — no IFD, no committed codegen;
`drowse.crate2nix` does per-crate Rust caching from Cargo.lock;
`drowse.instantiate` defers arbitrary evals. Hosts that should *build*
drowse packages include `den.aspects.dynamic-derivations` (currently:
joe-desktop). Remote builders need the features too, and attic must accept
CA realisations before relying on the cache for drowse-built outputs.

## Conventions for new things

- New feature → one file: `modules/<area>/<feature>.nix` assigning
  `den.aspects.<feature>.<class> = <module>`; big payloads as `_`-siblings.
- New host → `modules/hosts/<name>/default.nix` declaring
  `den.hosts.<system>.<name>.users.joe` + includes; concerns as sibling
  files merging into `den.aspects.<name>`.
- Cross-class features: use the `os` class (forwards to nixos + darwin) or
  separate class blocks in the same aspect (see services/attic.nix).
- Never reference `username`/`dotfiles-secrets`/… as module args — close
  over `inputs` from the flake-parts file header and import
  `modules/_lib/meta.nix`.
