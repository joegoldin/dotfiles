# Package sets and overlays

`modules/flake/package-sets.nix` constructs the common stable and unstable
package sets once per platform. Flake outputs and ordinary hosts reuse them.
The provider is also exposed as `lib.packageSets.<system>` for evaluation and
inspection. A separate plain set reuses nixpkgs' `legacyPackages` for isolated
module-test fixtures that do not need host policy.

The `nix-settings` aspect supplies `nixpkgs.pkgs`, leaving `nixpkgs.config`
empty: configuration policy belongs to the supplied set. NixOS and nix-darwin
append any host-local `nixpkgs.overlays` to that base. Jovian, Raspberry Pi,
erdtree's Garnix fixes, and torrent's brew-nix therefore retain their own
variants; do not replace those overlays with leaf packages.

`./default.nix` takes `{ inputs, packageSets }` and returns named overlays.
`modules/flake/overlays.nix` exports them, excluding the `unstableOverlays`
helper list. The provider applies them in alphabetical attribute-name order.

| Overlay | Purpose |
| --- | --- |
| `modifications` | Stable dependency patches, including Haskell/Python scope fixes |
| `unstable-packages` | Compatibility bridge from `pkgs.unstable` to the shared unstable set; retained dependency patches use it internally |
| `tinygrad-packages` | Upstream tinygrad package overrides |
| `affinity-packages` | Upstream Affinity package composition |

`unstableOverlays` applies tinygrad and the unstable dependency fixes inside
the shared unstable set. It no longer creates a fresh unstable import for
every stable host or output.

## Leaf packages

`modules/flake/_custom-packages.nix` composes local `_pkgs` packages and
upstream artifacts into `customPackages`, supplied to OS and Home Manager
modules. Home Manager still uses the host's global nixpkgs. Consume a leaf as
`customPackages.sem`, for example, rather than adding an alias to `pkgs`.
Upstream-built artifacts keep their own pins and binary-cache identities;
tailcat keeps its existing test override. Local packages remain available
through `packages.<system>`.

Elphael and volcano-manor include `den.aspects.vllm`, whose isolated ROCm
scope lives in [`modules/ai/_vllm`](../../ai/_vllm). Both use the same package
composition, targets (`gfx1100;gfx1201`), and two patches.
`programs.vllm-rocm.enable` defaults to false; enabling it on a host restores
both the application and that host's installed-app check. The check outputs
are absent while disabled, not passing GPU runtime tests.

The common Python environment keeps its existing CPU-only Torch policy.
Volcano-manor's removed global ROCm import was already superseded by the
shared unstable overlay; its presence did not mean that environment's Torch
had GPU support.

## Evaluation checks

[`package-set-checks.nix`](../package-set-checks.nix) asserts that the removed
aliases stay absent, the unstable bridge resolves to the shared set, upstream
`sem` and `audiomemo` derivation identities are retained, and package policy
and tailcat's test override remain intact. Evaluate without building:

```fish
nix eval --raw .#checks.x86_64-linux.package-sets.drvPath --option allow-import-from-derivation false
```

Run this from the repository root, replacing the platform for other configured
systems. These assertions check composition, not application runtime behavior
or whether a binary cache currently has a substitute.

See the [local package guide](../_pkgs/README.md) for registration and consumer
examples.

## Where does a change go?

- Stable dependency patch: `modifications`.
- Unstable dependency patch: `unstableOverlays`.
- New local leaf package: `../_pkgs`; consume through `customPackages`.
- Upstream-built artifact: `../_custom-packages.nix`, not a namespace overlay.
- Host-specific dependency policy: the host's `nixpkgs.overlays`.
- New shared package policy: the package-set provider, with explicit consumers.
