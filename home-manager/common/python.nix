{
  pkgs,
  lib,
  ...
}: let
  pythonBase = pkgs.python3;

  # Standard packages from nixpkgs
  nixPythonPackages = with pythonBase.pkgs;
    [
      anthropic
      black
      flake8
      flask
      isort
      jupyter
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

  # Define claudesync package manually with its dependencies
  claudesync = pythonBase.pkgs.buildPythonPackage rec {
    pname = "claudesync";
    version = "0.7.1";
    format = "setuptools";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/source/c/claudesync/claudesync-${version}.tar.gz";
      sha256 = "sha256-6gficPfbj4PpvX4k0MpPQQP7DDPb022Yen5LPGaZF/I=";
    };

    # Manually specify all dependencies
    propagatedBuildInputs = with pythonBase.pkgs; [
      sseclient
      crontab
    ];

    # Disable tests - they might try to access network or require API keys
    doCheck = false;

    # Basic import check
    pythonImportsCheck = ["claudesync"];

    meta = with lib; {
      description = "Claude CLI for synchronizing files";
      homepage = "https://pypi.org/project/claudesync/";
      license = licenses.mit;
    };
  };

  # Final Python environment with all packages
  pythonWithPackages = pythonBase.withPackages (
    ps:
      nixPythonPackages ++ [claudesync]
  );
in
  pythonWithPackages
