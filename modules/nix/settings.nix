# Repo-wide nix daemon + nixpkgs settings. cloud-proxy includes
# `den.aspects.nix-settings`; the other hosts still carry their own (nearly
# identical) copies inside modules/hosts/*/_configuration.nix — dedup them
# into this aspect as follow-up cleanup (watch the per-host deltas:
# steamdeck gc 14d/auto-optimise, office-pc cores=20, macbook max-jobs).
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
