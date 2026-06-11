# Custom packages and modifications exported as overlays.
# Overlay definitions live in ./_overlays (invisible to import-tree).
{ inputs, ... }:
{
  flake.overlays = builtins.removeAttrs (import ./_overlays {
    inherit inputs;
  }) [ "unstableOverlays" ];
}
