# Module-args shim: the moved legacy modules (everything that lived under
# hosts/) consumed these names from specialArgs; den provides them via
# _module.args instead — the standard module-system mechanism, applied to
# every den entity through den.default. All consumption is body-level
# (imports never reference these), which is exactly what _module.args
# supports.
#
# TRANSITIONAL: shrink this as modules are rewritten to close over
# inputs/meta directly (grep for an arg name before removing it).
# `hostname` is deliberately NOT here — each host sets
# `_module.args.hostname` in its own aspect.
{ config, inputs, lib, ... }:
let
  meta = import ../_lib/meta.nix;
  keys = import "${inputs.dotfiles-secrets}/keys.nix";
  # was `inputs // commonSpecialArgs` in the old flake.nix
  osArgs = inputs // {
    inherit inputs keys;
    commonOverlays = builtins.attrValues config.flake.overlays;
    username = meta.username;
    useremail = meta.email;
    stateVersion = "24.11";
  };
in
{
  den.default.nixos._module.args = osArgs;
  den.default.darwin._module.args = osArgs;

  den.default.homeManager =
    { pkgs, ... }:
    {
      _module.args = osArgs // {
        homeDirectory = lib.mkForce (
          (if pkgs.stdenv.isDarwin then "/Users/" else "/home/") + meta.username
        );
      };
    };
}
