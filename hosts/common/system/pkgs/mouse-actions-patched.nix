# Patched mouse-actions: replicates hosts/common/system/drag-shift.nix logic
# inside the gesture daemon so a single process owns the grabbed mouse.
#
# The patch only touches src/grab.rs (no dependency changes), so the upstream
# cargoHash stays valid and we just slot it in via cargoPatches.
{ mouse-actions }:
mouse-actions.overrideAttrs (old: {
  pname = "mouse-actions-drag-shift";
  cargoPatches = (old.cargoPatches or [ ]) ++ [
    ./mouse-actions-drag-shift.patch
  ];
})
