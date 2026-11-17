# Module architecture

This repository uses import-tree to discover flake-parts modules and Den to
compose host and user features. The pinned Den release calls this
**aspect-oriented, context-driven Nix**, and explicitly distinguishes itself
from the original Dendritic pattern. Keep the useful file-discovery convention
without assuming that every Dendritic tutorial describes Den's current API.

## Ownership and selection

- Auto-imported files contribute flake-parts configuration. A file defining an
  aspect does not install that feature everywhere: a host, user, or another
  aspect must include it.
- Select features with `den.aspects.<name>` in `includes`. Do not add a second
  repository-owned enable option or silently disable a selected feature when
  its required package is missing. Missing dependencies should fail evaluation.
- Upstream options such as `programs.git.enable` still belong inside the
  selected aspect. Platform conditions, optional credentials, and application
  safety settings are not substitutes for aspect selection and remain valid.
- Shared features belong under `home/`, `system/`, `services/`, `ai/`, or `nix/`.
  Host files own hardware, deployment policy, and host-specific overrides.
  Splitting a host aspect across several files is supported; it does not need
  a new shared abstraction until the behavior is actually reusable.
- Files beneath underscore-prefixed paths are explicit helpers, not auto-loaded
  flake-parts modules. Package functions, fixtures, standalone Home Manager
  modules, and generated guest modules belong behind that boundary.

For example, [`vllm.nix`](../ai/vllm.nix) installs the application whenever its
aspect is included. The two GPU hosts currently omit that include. The
[installed-application checks](vllm-checks.nix) inspect their resulting package
lists, rather than maintaining a second enable flag.

## Host and user routing

[`den.nix`](den.nix) explicitly selects the hostname, host-aspects, and
mutual-provider batteries and acknowledges the user/host-content migration.
Home Manager is selected through `den.schema.user.classes`. User account and
SSH-key contributions flow through `provides.to-hosts`; host-selected home
features flow through host-aspects. Do not reintroduce reliance on Den's
transitional implicit routing defaults.

[`hm-settings.nix`](../home/hm-settings.nix) uses the host's final package set
with `useGlobalPkgs` and forwards only `customPackages` across the OS/Home
Manager boundary. Top-level flake inputs are captured by the aspect's module,
not copied wholesale into every module argument set. `_module.args` is suitable
for package values used by configuration; it must not determine `imports`,
which the module system resolves earlier.

Scarab intentionally imports Codex and Antigravity's **option schemas** without
including their enabling aspects. The shared agent-skills MCP module references
those option paths even when the programs are disabled. Keep that distinction;
importing an upstream schema is not selecting an application.

## Packages and flake outputs

[`package-sets.nix`](package-sets.nix) derives its platform keys from
flake-parts' `config.systems` and owns shared stable, unstable, and plain sets.
The dev shell deliberately uses the plain set; the formatter deliberately uses
upstream unstable. Host overlays may extend stable for real dependency patches.
Do not collapse Jovian, Garnix, brew-nix, or upstream artifact pins merely to
make the imports look uniform: their dependency and cache identities matter.

Local applications are composed as `customPackages`, not injected as aliases
into the nixpkgs fixpoint. [`packages.nix`](packages.nix) exports only
platform-available derivations; constructors such as `mkWindowsApp` stay in
`customPackages`. [`package-exports-checks.nix`](package-exports-checks.nix)
checks membership, platform support, and derivation identity.

Keep system-dependent flake outputs under `perSystem`. Use its `pkgs`,
`system`, and `config` arguments; capture top-level inputs and configuration in
the enclosing module when needed. The installer ISO is an intentional direct
`nixosConfigurations` artifact, not a regular host entity. Runtime-generated
microVMs also remain standalone: they evaluate outside the Den host graph.

## Review scope and verification

The November 2026 architecture pass inventoried the complete Nix module tree,
reviewed auto-imported module ownership/composition and explicit-helper risk
sites, and consulted the pinned Den, import-tree, and flake-parts sources.
It removed redundant feature gates, moved shared Darwin Rex configuration out
of the torrent directory, unified the systems source, and corrected
foreign-platform package exports.

The review preserved state versions, secret recipients, service safety gates,
platform guards, dependency patches, and host-specific package policies.
Existing lint suggestions about empty function patterns, repeated attribute
keys, and `inherit` spelling were not used as a reason to rewrite the tree.
A module architecture review is not a security audit of every embedded script
or a claim that all applications build and run.

Evaluation-only checks:

```fish
nix flake check --no-build --all-systems --option allow-import-from-derivation false
nix eval --raw .#checks.x86_64-linux.aspect-selection.drvPath --option allow-import-from-derivation false
nix eval --raw .#checks.aarch64-darwin.package-exports.drvPath --option allow-import-from-derivation false
```

Evaluate all host toplevel derivations as well; a successful flake check alone
does not force every host's complete system closure. Build and live acceptance
remain separate steps. Never switch systems merely to validate a structural
refactor.

Pinned-framework references:

- [Den core principles](https://den.denful.dev/explanation/core-principles/)
- [Den aspect structure](https://den.denful.dev/reference/aspects/)
- [Den home integration](https://den.denful.dev/guides/home-manager/)
- [flake-parts module arguments](https://flake.parts/module-arguments.html)
- [import-tree](https://github.com/denful/import-tree)

The lock file, not the current version of those websites, determines the API
available to this checkout.
