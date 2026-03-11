{
  pkgs,
  lib,
  unstable,
  extraPackages ? (_ps: [ ]),
  ...
}:
let
  pythonBase = unstable.python3.override {
    packageOverrides = pyFinal: pyPrev: {
      # plotly: tests fail with pytest 9.x due to deprecated py.path.local API
      plotly = pyPrev.plotly.overrideAttrs (old: {
        doInstallCheck = false;
      });

      # wandb: test_printer_asyncio spinner tests are flaky in the sandbox
      wandb = pyPrev.wandb.overrideAttrs (old: {
        disabledTestPaths = (old.disabledTestPaths or [ ]) ++ [
          "tests/unit_tests/test_lib/test_printer_asyncio.py"
        ];
      });

    };
  };

  # Import custom package definitions
  customPackages = import ./custom-pypi-packages.nix {
    inherit
      pkgs
      lib
      pythonBase
      unstable
      ;
  };

  # Standard packages from nixpkgs
  nixPythonPackages =
    with pythonBase.pkgs;
    [
      anthropic
      beautifulsoup4
      black
      brotli
      brotlipy
      colorama
      cryptography
      datasets
      dbus-python
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
      # pdoc3
      pandas
      pip
      playwright
      playwright-stealth
      pytest
      requests
      scikit-learn
      scrapy
      sentry-sdk
      setuptools
      soupsieve
      tabulate
      transformers
      wandb
      watchdog
      wheel
      wxpython
      zlib-ng
    ]
    ++ lib.optionals (!pkgs.stdenv.isDarwin) (
      with pythonBase.pkgs;
      [
        screeninfo
        xcffib
      ]
    );

  # Final Python environment with all packages
  pythonWithPackages = pythonBase.withPackages (
    ps:
    nixPythonPackages
    ++ (extraPackages pythonBase.pkgs)
    ++ [
      # Custom packages from PyPI
      customPackages.deepgram-sdk
      customPackages.fal-client
      # customPackages.llm
      # customPackages.llm-anthropic
      # customPackages.llm-cmd
      # customPackages.llm-cmd-comp
      # customPackages.llm-deepseek
      # customPackages.llm-gemini
      # customPackages.llm-grok
      # customPackages.llm-ollama
      # customPackages.llm-perplexity
      customPackages.lmstudio
      customPackages.modal
      customPackages.scrapy-playwright
      customPackages.scrapfly-sdk
    ]
    ++ (
      if (pkgs.stdenv.isDarwin && pkgs.stdenv.isAarch64) then
        [
          customPackages.mlx
          # customPackages.mlx-lm
          # customPackages.llm-mlx
        ]
      else
        [
        ]
    )
  );

  # Create an FHS environment for Python
  pythonFHSEnv = pkgs.buildFHSEnv {
    name = "python-fhs-env";
    targetPkgs = pkgs: [
      pythonWithPackages
    ];
    runScript = "bash";
    extraBuildCommands = ''
      # Create standard Python symlinks
      mkdir -p usr/bin
      ln -s ${pythonWithPackages}/bin/python usr/bin/python
      ln -s ${pythonWithPackages}/bin/python3 usr/bin/python3
    '';
  };
in
{
  packages = pythonWithPackages;
  fhs = pythonFHSEnv;

  # Add Home Manager activation script to run post-install commands
  pythonPostInstall = lib.hm.dag.entryAfter [ "installPackages" ] ''
    echo "Running Python package post-installation tasks..."

    # Changed to use a direct iteration over the packages with non-empty postInstall
    ${lib.concatStringsSep "\n" (
      lib.filter (cmd: cmd != "") (
        map (
          pkg:
          if pkg ? postInstall && pkg.postInstall != "" then
            ''
              echo "Running post-install configuration for ${pkg.pname}..."
              run ${pkg.postInstall}
            ''
          else
            ""
        ) (lib.attrValues customPackages)
      )
    )}
  '';
}
