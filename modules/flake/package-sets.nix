# Construct each common package policy once; aspects consume these values
# rather than importing nixpkgs again. Host-local overlays still extend stable.
{
  inputs,
  config,
  lib,
  ...
}:
let
  packageSets = lib.genAttrs (import inputs.systems) (
    system:
    let
      stable = import inputs.nixpkgs {
        inherit system;
        overlays = builtins.attrValues config.flake.overlays;
        config = {
          allowUnfree = true;
          allowUnsupportedSystem = true;
          experimental-features = "nix-command flakes";
        };
      };
      unstable = import inputs.nixpkgs-unstable {
        inherit system;
        overlays = (import ./_overlays { inherit inputs packageSets; }).unstableOverlays;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
          # torch-bin incorrectly checks CUDA compatibility on Darwin too.
          problems.handlers.torch.unsupported-cuda-version = "warn";
        };
      };
      mkCustomPackages = pkgs: import ./_custom-packages.nix { inherit inputs pkgs; };
    in
    {
      inherit stable unstable mkCustomPackages;
      plain = inputs.nixpkgs.legacyPackages.${system};
      customPackages = mkCustomPackages stable;
    }
  );
in
{
  _module.args.packageSets = packageSets;
  flake.lib.packageSets = packageSets;

  perSystem = { system, ... }: {
    _module.args = {
      pkgs = packageSets.${system}.stable;
      inherit (packageSets.${system}) customPackages;
    };
  };
}
