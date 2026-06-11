# den (github:denful/den) — the aspect engine on top of the dendritic
# pattern. Every .nix file under modules/ is a flake-parts module imported
# automatically by import-tree (paths containing "/_" are skipped); this one
# wires den itself plus repo-wide entity defaults.
{ inputs, lib, ... }:
{
  imports = [ inputs.den.flakeModule ];

  # Every user entity gets a home-manager environment by default
  # (was: home-manager.nixosModules.home-manager wired per-host in flake.nix).
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  # Was `stateVersion` in commonSpecialArgs. Hosts that intentionally diverge
  # (e.g. cloud-proxy is 25.11) override in their own aspect.
  den.default.nixos.system.stateVersion = lib.mkDefault "24.11";
  den.default.homeManager.home.stateVersion = lib.mkDefault "24.11";
}
