# Repo-wide nix daemon + nixpkgs settings, lifted verbatim from the nix/
# nixpkgs blocks every hosts/*/configuration.nix repeats. den hosts include
# `den.aspects.nix-settings`; legacy hosts keep their own copy until migrated.
{ config, inputs, ... }:
let
  meta = import ../_lib/meta.nix;
  flakeOverlays = builtins.attrValues config.flake.overlays;
  flakeInputs = inputs;
in
{
  den.aspects.nix-settings.nixos =
    { config, lib, pkgs, ... }:
    let
      registryInputs = lib.filterAttrs (_: lib.isType "flake") flakeInputs;
    in
    {
      nixpkgs = {
        overlays = flakeOverlays;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
          experimental-features = "nix-command flakes";
        };
      };

      nix = {
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          nix-path = config.nix.nixPath;
          trusted-users = [ meta.username ];
          auto-optimise-store = false;
        };

        gc = {
          automatic = lib.mkDefault true;
          options = lib.mkDefault "--delete-older-than 7d";
        };

        extraOptions = lib.optionalString (
          config.nix.package == pkgs.nixVersions.stable
        ) "experimental-features = nix-command flakes";

        registry = lib.mapAttrs (_: flake: { inherit flake; }) registryInputs;
        nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") registryInputs;

        channel.enable = false;
      };
    };
}
