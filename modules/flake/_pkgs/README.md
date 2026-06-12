# Custom packages

callPackage-style package definitions (underscored: these are functions,
not flake-parts modules). They surface in two ways:

- `nix build .#<name>`, via the `packages` output
  (`modules/flake/packages.nix` imports `./default.nix` with a
  fully-overlaid pkgs)
- `pkgs.<name>` inside any host/home module, via the `additions` overlay
  (`modules/flake/_overlays/default.nix`)

Add a package: write `foo.nix` (or `foo/default.nix`) here, register it in
`./default.nix`. Vendored/derivative code in this tree is credited in the
root README's Attribution section; see `mac-app-util/` (AGPL-3.0 port)
and `mkwindowsapp/`.
