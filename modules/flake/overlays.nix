# Custom packages and modifications exported as overlays.
# Still sourced from the legacy location while hosts/ exists; the overlay
# definitions themselves move into modules/ near the end of the migration
# (see MIGRATION.md phase 6).
{ inputs, ... }:
{
  flake.overlays = builtins.removeAttrs (import ../../hosts/common/system/overlays {
    inherit inputs;
  }) [ "unstableOverlays" ];
}
