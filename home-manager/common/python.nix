{pkgs, ...}:
with pkgs; (python3.withPackages (ps:
    with ps;
      [
        (aiohttp.overridePythonAttrs (_: {doCheck = false;}))
        anthropic
        black
        flake8
        flask
        isort
        jupyter
        numpy
        ollama
        openai
        scikit-learn
        tabulate
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
