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
      llm
      numpy
      ollama
      openai
      pip
      requests
      scikit-learn
      setuptools
      tabulate
      wheel
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
        customPackages.claudesync
        customPackages.fal-client
        customPackages.llm-anthropic
        customPackages.llm-cmd
        customPackages.llm-cmd-comp
        customPackages.llm-deepseek
        customPackages.llm-gemini
        customPackages.llm-grok
        customPackages.llm-ollama
        customPackages.llm-perplexity
      ]
  );
in
  pythonWithPackages
