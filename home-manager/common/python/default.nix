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
      beautifulsoup4
      black
      brotli
      brotlipy
      colorama
      cryptography
      extruct
      fake-useragent
      faker
      flake8
      flask
      isort
      jupyter
      lxml
      msgpack
      numpy
      ollama
      openai
      pdoc3
      pandas
      pip
      playwright
      playwright-stealth
      requests
      scikit-learn
      scrapy
      scrapy-fake-useragent
      sentry-sdk
      setuptools
      soupsieve
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
        customPackages.scrapfly-sdk
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
in {
  packages = pythonWithPackages;

  # Add Home Manager activation script to run node post-install commands
  pythonPostInstall = lib.hm.dag.entryAfter ["installPackages"] ''
    echo "Running Python package post-installation tasks..."
    
    # Changed to use a direct iteration over the packages with non-empty postInstallCommands
    ${lib.concatStringsSep "\n" (lib.filter (cmd: cmd != "") (map (pkg: 
      if pkg ? postInstallCommands && pkg.postInstallCommands != ""
      then ''
        echo "Running post-install configuration for ${pkg.pname}..."
        run ${pkg.postInstallCommands}
      ''
      else ""
    ) (lib.attrValues customPackages)))}
  '';
}
