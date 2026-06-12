# Repo-wide nix daemon + nixpkgs settings — included by every host via its
# aspect. The `os` half serves both nixos and darwin; per-host deltas
# (cores, gc cadence, extra platforms) live in each host's system file.
{ config, inputs, ... }:
let
  meta = import ../_lib/meta.nix;
  flakeOverlays = builtins.attrValues config.flake.overlays;
  flakeInputs = inputs;
in
{
  den.aspects.nix-settings.os =
    {
      config,
      lib,
      pkgs,
      ...
    }:
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
          auto-optimise-store = lib.mkDefault false;
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
      };
    };

  # Linux-only bits.
  den.aspects.nix-settings.nixos = {
    # Disable channels entirely - use flakes only
    nix.channel.enable = false;

    programs.nh = {
      enable = true;
      flake = "/home/${meta.username}/dotfiles";
    };
  };
}
