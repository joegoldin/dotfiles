# Repo-wide nix daemon + nixpkgs settings; included by every host via its
# aspect. The `os` half serves both nixos and darwin; per-host deltas
# (cores, gc cadence, extra platforms) live in each host's system file.
{ inputs, packageSets, ... }:
let
  meta = import ../_lib/meta.nix;
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
      # NixOS/nix-darwin append host-local overlays to this base. Their
      # nixpkgs.config stays empty: policy belongs to the supplied package set.
      nixpkgs.pkgs = lib.mkDefault packageSets.${config.nixpkgs.hostPlatform.system}.stable;
      _module.args.customPackages = packageSets.${pkgs.stdenv.hostPlatform.system}.mkCustomPackages pkgs;

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
