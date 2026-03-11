# ML packages for macOS (pre-built torch binaries)
{
  custom.python.extraPackages =
    ps: with ps; [
      torch-bin
      torchvision-bin
    ];
}
