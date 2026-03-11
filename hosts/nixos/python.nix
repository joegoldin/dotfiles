# ML packages for desktop (torch, torchvision with ROCm)
{
  custom.python.extraPackages =
    ps: with ps; [
      datasets
      scikit-learn
      torch
      torchvision
      transformers
      wandb
    ];
}
