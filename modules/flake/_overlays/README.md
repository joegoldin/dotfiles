# Overlays

`./default.nix` is a function `{ inputs }: { … }` returning named overlays.
`modules/flake/overlays.nix` exports them as `flake.overlays` (minus the
`unstableOverlays` helper list), and the `nix-settings` aspect applies
`attrValues` of that set to every host's `nixpkgs.overlays`, so
anything defined here exists on all machines and in the `packages` output.
Note `attrValues` means overlays compose in *alphabetical attr-name order*;
nothing here depends on ordering today, keep it that way.

The named overlays:

| Overlay | Provides |
| --- | --- |
| `additions` | every package from `../_pkgs` as `pkgs.<name>` |
| `modifications` | fixes/patches to stable nixpkgs packages (flaky-test `doCheck` disables, pipenv site-packages cleanup, freerdp/openh264 swap, howdy patch) |
| `unstable-packages` | `pkgs.unstable`, a second nixpkgs evaluation of `nixpkgs-unstable` (allowUnfree + android_sdk license), with `unstableOverlays` applied |
| `<input>-packages` | re-exported overlays from flake inputs: tinygrad, claude-desktop, llm-agents, audiomemo, claude-container, affinity, mcps (inlined to avoid its deprecated `pkgs.system` use) |

## The two-layer `unstable` scheme

`unstableOverlays` (the attr stripped from the export) is the list of
overlays applied inside the `pkgs.unstable` evaluation: the pulsemeeter
fork, ibis-framework/openldap test disables, tinygrad. It exists as a
separate, reusable list so hosts that need a *custom* unstable can rebuild
it without losing those patches: volcano-manor's `system.nix` adds a later
overlay that re-imports nixpkgs-unstable with `rocmSupport = true` and
`unstableOverlays ++ [ ./vllm-rocm.nix ]`; later overlays win, replacing
the stock `pkgs.unstable` on that host only.

`./vllm-rocm.nix` is that volcano-manor-only overlay: a `vllm-rocm` application
built as an isolated leaf so the rest of `unstable.python3Packages` keeps
upstream hashes (and cache hits).

## Where does my change go?

- Fix/patch a **stable** package → `modifications`
- Fix/patch something under **`pkgs.unstable`** → the fix overlay inside
  `unstableOverlays`
- New **custom package** → `../_pkgs` (picked up by `additions`)
- Overlay shipped by a **new flake input** → a new `<name>-packages` attr
- **Host-specific** package-set variant → a later overlay in that host's
  `system.nix` (see volcano-manor), not here
