# ML packages for desktop (torch, torchvision with ROCm)
{ pkgs, ... }:
{
  custom.python.extraPackages =
    ps: with ps; [
      datasets
      scikit-learn
      pkgs.python3Packages.tinygradWithRocm
      torch
      torchvision
      transformers
      wandb
    ];
}
