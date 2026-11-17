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

Both GPU hosts include `den.aspects.vllm`, whose isolated ROCm scope lives in
`modules/ai/_vllm`. It preserves elphael's targets and patches without changing
the host's entire unstable policy. `programs.vllm-rocm.enable` is temporarily
false; enabling it restores the application and the installed-app check.
The common Python environment keeps its existing CPU-only Torch policy.
Volcano-manor's old global ROCm overlay was superseded by the shared unstable
overlay; removing it does not remove working GPU support from that environment.

## Where does a change go?

- Stable dependency patch: `modifications`.
- Unstable dependency patch: `unstableOverlays`.
- New local leaf package: `../_pkgs`; consume through `customPackages`.
- Upstream-built artifact: `../_custom-packages.nix`, not a namespace overlay.
- Host-specific dependency policy: the host's `nixpkgs.overlays`.
- New shared package policy: the package-set provider, with explicit consumers.
