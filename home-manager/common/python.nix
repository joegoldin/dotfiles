{pkgs, ...}:
with pkgs; (python3.withPackages (ps:
    with ps;
      [
        jupyter
        numpy
        scikit-learn
      ]
      ++ (
        if (stdenv.isDarwin && stdenv.isAarch64)
        then
          with ps; [
            torch-bin
            torchvision-bin
          ]
        else
          with ps; [
            torch
            torchvision
          ]
      )))
