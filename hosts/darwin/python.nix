# ML packages for macOS (pre-built torch binaries + MLX)
{ pkgs, lib, ... }:
let
  inherit (pkgs) unstable;
  customPackages = import ../common/home/python/custom-pypi-packages.nix {
    inherit pkgs lib;
    pythonBase = unstable.python3;
  };
in
{
  custom.python.extraPackages =
    ps: with ps; [
      datasets
      scikit-learn
      torch-bin
      torchvision-bin
      transformers
      wandb
      customPackages.mlx
    ];
}
