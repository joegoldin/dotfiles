{
  pkgs,
  lib,
  unstable,
  extraPackages ? (_ps: [ ]),
  ...
}:
let
  # Use unstable.python3 directly — do NOT override packageOverrides here.
  # That pattern re-derives the entire python3 package set identity and
  # cascades a rebuild across every consumer in the closure (and forfeits
  # cache.nixos.org / attic substitutes). Leaf overrides needed by the env
  # are applied inside `pythonBase.withPackages` below, scoped to this env
  # only — they don't leak into `unstable.python3Packages` at large.
  pythonBase = unstable.python3;

  # Import custom package definitions
  customPackages = import ./custom-pypi-packages.nix {
    inherit
      pkgs
      lib
      pythonBase
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
      dbus-python
      extruct
      fake-useragent
      faker
      flake8
      flask
      isort
      llm
      llm-anthropic
      llm-cmd
      llm-deepseek
      llm-gemini
      llm-grok
      llm-perplexity
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
      scrapy
      sentry-sdk
      setuptools
      soupsieve
      tabulate
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

  # Final Python environment.
  #
  # Leaf overrides are applied here, inside `withPackages`, instead of via
  # `python3.override { packageOverrides = ... }` at the top of this file —
  # that would change the identity of the whole python3 package set and
  # cascade a rebuild across every transitive consumer. By patching only the
  # specific packages this env consumes (wandb, torch-bin) and threading the
  # patched set into `extraPackages`, the rest of `pythonBase.pkgs` stays at
  # its upstream hashes and substitutes cleanly.
  pythonWithPackages = pythonBase.withPackages (
    ps:
    let
      psPatched = ps // {
        # wandb: test_printer_asyncio spinner tests are flaky in the sandbox
        wandb = ps.wandb.overrideAttrs (old: {
          disabledTestPaths = (old.disabledTestPaths or [ ]) ++ [
            "tests/unit_tests/test_lib/test_printer_asyncio.py"
          ];
        });

        # torch-bin: wheel requires fsspec but nixpkgs doesn't include it
        torch-bin = ps.torch-bin.overridePythonAttrs (old: {
          dependencies = (old.dependencies or [ ]) ++ [ ps.fsspec ];
        });
      };
    in
    nixPythonPackages
    ++ (extraPackages psPatched)
    ++ [
      # Custom packages from PyPI
      customPackages.deepgram-sdk
      customPackages.fal-client
      customPackages.lmstudio
      customPackages.modal
      customPackages.scrapy-playwright
      customPackages.scrapfly-sdk
    ]
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
