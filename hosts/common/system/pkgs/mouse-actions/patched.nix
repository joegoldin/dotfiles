# Patched mouse-actions: drag-shift and forward+back chord baked into the
# gesture daemon so a single process owns the grabbed mouse.
#
# We must use `patches` (not `cargoPatches`) here: `cargoPatches` is folded
# into `patches` only when rustPlatform.buildRustPackage builds the original
# derivation. `overrideAttrs` runs after that aggregation, so a `cargoPatches`
# override is a silent no-op. patchPhase consumes `patches`.
#
# The patch only touches src/grab.rs (no Cargo.lock changes), so the upstream
# cargoHash stays valid.
{ mouse-actions }:
mouse-actions.overrideAttrs (old: {
  pname = "mouse-actions-drag-shift";
  patches = (old.patches or [ ]) ++ [
    ./drag-shift.patch
  ];
})
