# ML packages for desktop (torch, torchvision with ROCm)
{
  custom.python.extraPackages =
    ps: with ps; [
      datasets
      scikit-learn
      # tinygradWithRocm temporarily disabled — upstream test suite hits
      # "sqlite3.OperationalError: database is locked" under parallel builds.
      torch
      torchvision
      transformers
      wandb
    ];
}
