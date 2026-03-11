# ML packages for desktop (torch, torchvision with ROCm)
{
  custom.python.extraPackages =
    ps: with ps; [
      torch
      torchvision
    ];
}
