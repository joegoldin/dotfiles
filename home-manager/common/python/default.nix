{
  pkgs,
  lib,
  unstable,
  ...
}: let
  pythonBase = unstable.python3;

  # Import custom package definitions
  customPackages = import ./custom-pypi-packages.nix {inherit pkgs lib pythonBase unstable;};

  # Standard packages from nixpkgs
  nixPythonPackages = with pythonBase.pkgs;
    [
      anthropic
      black
      brotli
      cryptography
      flake8
      flask
      isort
      jupyter
      numpy
      ollama
      openai
      pip
      playwright
      requests
      scikit-learn
      setuptools
      tabulate
      wheel
      zlib-ng
    ]
    ++ (
      if (pkgs.stdenv.isDarwin && pkgs.stdenv.isAarch64)
      then
        with pythonBase.pkgs; [
          torch-bin
          torchvision-bin
        ]
      else
        with pythonBase.pkgs; [
          torch
          torchvision
        ]
    );

  # Final Python environment with all packages
  pythonWithPackages = pythonBase.withPackages (
    ps:
      nixPythonPackages
      ++ [
        # Custom packages from PyPI
        customPackages.deepgram-sdk
        customPackages.fal-client
        customPackages.llm
        customPackages.llm-anthropic
        customPackages.llm-cmd
        customPackages.llm-cmd-comp
        customPackages.llm-deepseek
        customPackages.llm-gemini
        customPackages.llm-grok
        customPackages.llm-ollama
        customPackages.llm-perplexity
        customPackages.lmstudio
      ]
      ++ (
        if (pkgs.stdenv.isDarwin && pkgs.stdenv.isAarch64)
        then [
          customPackages.mlx
          customPackages.mlx-lm
          customPackages.llm-mlx
        ]
        else [
        ]
      )
  );
in
  pythonWithPackages
