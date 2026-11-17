# Local packages

This directory contains package definitions, not flake-parts modules. Its
underscore-prefixed path keeps import-tree from loading the files as modules.
[`default.nix`](default.nix) takes `pkgs` and returns the local package set.

Local package derivations surface in two ways:

- `nix build .#<name>`, through the `packages.<system>` output in
  [`../packages.nix`](../packages.nix).
- `customPackages.<name>` inside OS and Home Manager modules, through
  [`../_custom-packages.nix`](../_custom-packages.nix) and the shared provider.
  There is no `additions` overlay or automatic `pkgs.<name>` alias.

The flake export includes only derivations available on the target platform.
Linux-only packages are not advertised as Darwin build targets. Constructors such as
`mkWindowsApp` remain callable through `customPackages.mkWindowsApp` but are
not standalone `nix build` targets. `checks.<system>.package-exports` verifies
this boundary and preserves the derivation identities of the exported packages.

Add a package by writing `foo.nix` or `foo/default.nix` here and registering it
in `default.nix`, usually with `pkgs.callPackage`. Accept `customPackages` as
a module argument where the package is used:

```nix
{ customPackages, ... }:
{
  home.packages = [ customPackages.litra ];
}
```

Flake-parts `perSystem` modules receive the same argument. Host consumers
compose local packages against their host's final `pkgs`, preserving any
host-specific dependency overlays. Standalone modules used outside the host
wiring must supply their own `customPackages` argument.

Upstream-built artifacts such as `sem` and `audiomemo` belong in
`../_custom-packages.nix`; they are not local definitions and are not
implicitly re-exported as this repository's `packages` outputs. Dependency
patches belong in an overlay, not in a leaf alias. See the
[package-set and overlay guide](../_overlays/README.md).

`just update-pkgs` updates a curated list of local packages with nix-update;
it does not update every definition here. Review the exclusions in the
[Justfile](../../../Justfile), especially custom fixed-output hashes such as
zmx's `zigDeps`.

Vendored and derivative code is credited in the root
[Attribution section](../../../README.md#attribution). In particular,
`mac-app-util/` retains its AGPL-3.0 license and `mkwindowsapp/` its upstream
MIT attribution.
