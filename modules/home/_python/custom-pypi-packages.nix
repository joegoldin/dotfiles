{
  pkgs,
  lib,
  pythonBase,
  ...
}:
let
  # Define all packages in a recursive attribute set
  pythonPackages = rec {
    fal-client = pythonBase.pkgs.buildPythonPackage {
      pname = "fal-client";
      version = "1.0.3";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/f/fal_client/fal_client-1.0.3.tar.gz";
        sha256 = "sha256-8PCSDq6HGQDk7+oYZb4o1KYHp3nUPUelOoSY0s6Wkc0=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        setuptools
        wheel
        setuptools-scm
      ];
      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs; [
        aiofiles
        asyncstdlib
        httpx
        httpx-sse
        msgpack
        websockets
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = [ "fal_client" ];

      meta = with lib; {
        description = "Python client for fal.ai";
        homepage = "https://fal.ai";
        license = licenses.asl20;
      };
    };

    mlx-metal = pythonBase.pkgs.buildPythonPackage {
      pname = "mlx-metal";
      version = "0.26.5";
      format = "wheel";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/a6/a0/0e01714f94f3b0efe7f90581c4b27becba9df55d15fd562cbd45f3a6dec3/mlx_metal-0.26.5-py3-none-macosx_15_0_arm64.whl";
        sha256 = "sha256-9b05TH/27rqvjbbXvU+N7Jby0jLwi6ZBZzq2byLpcns=";
      };

      doCheck = false;

      # mlx-metal shares the mlx/ namespace with the main mlx package.
      # Remove Python stub files that conflict in buildEnv; the Metal
      # shaders (.metallib) are the actual payload.
      postFixup = ''
        rm -rf $out/lib/python*/site-packages/mlx/__pycache__
        rm -f $out/lib/python*/site-packages/mlx/__init__.py
        rm -f $out/lib/python*/site-packages/mlx/utils.py
      '';

      meta = with lib; {
        description = "MLX Metal backend for Apple silicon GPUs.";
        homepage = "https://github.com/ml-explore/mlx";
        license = licenses.mit;
      };
    };

    mlx = pythonBase.pkgs.buildPythonPackage {
      pname = "mlx";
      version = "0.26.5";
      format = "wheel";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/52/c1/8193c3adb61debec85d72cd9315c0e753f4ffd64ff2a4000e0e7f1e2b001/mlx-0.26.5-cp312-cp312-macosx_15_0_arm64.whl";
        sha256 = "sha256-d8W3ULJKGO1uQz3EbXhxk7EkqGmxtl0VMr+3037HFy8=";
      };

      # Dependencies
      propagatedBuildInputs = [ pythonPackages.mlx-metal ];

      doCheck = false;
      pythonImportsCheck = [ "mlx" ];

      meta = with lib; {
        description = "A framework for machine learning on Apple silicon.";
        homepage = "https://github.com/ml-explore/mlx";
        license = licenses.mit;
      };
    };

    deepgram-sdk = pythonBase.pkgs.buildPythonPackage {
      pname = "deepgram-sdk";
      version = "7.11.0";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/d/deepgram_sdk/deepgram_sdk-7.11.0.tar.gz";
        sha256 = "sha256-1ZoWKsK0GmXlkjsOGQ3MPkcKXpeRNE/S95ECLkCINzQ=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        setuptools
        wheel
        poetry-core
      ];
      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs; [
        httpx
        pydantic
        pydantic-core
        typing-extensions
        websockets
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = [ "deepgram" ];

      meta = with lib; {
        description = "The official Python SDK for the Deepgram automated speech recognition platform.";
        homepage = "https://github.com/deepgram/deepgram-python-sdk";
        license = licenses.mit;
      };
    };

    lmstudio = pythonBase.pkgs.buildPythonPackage {
      pname = "lmstudio";
      version = "1.5.0";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/l/lmstudio/lmstudio-1.5.0.tar.gz";
        sha256 = "sha256-RYw0/h+Up9zFIdQia0zugrivfqPajECzG72sVY2adNQ=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        setuptools
        wheel
        pdm-backend
      ];
      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs; [
        anyio
        httpx
        httpx-ws
        msgspec
        typing-extensions
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = [ "lmstudio" ];

      meta = with lib; {
        description = "LM Studio Python SDK";
        homepage = "https://github.com/lmstudio-ai/lmstudio-sdk-python";
        license = licenses.mit;
      };
    };
    types-certifi = pythonBase.pkgs.buildPythonPackage {
      pname = "types-certifi";
      version = "2021.10.8.3";
      format = "wheel";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/b5/63/2463d89481e811f007b0e1cd0a91e52e141b47f9de724d20db7b861dcfec/types_certifi-2021.10.8.3-py3-none-any.whl";
        sha256 = "sha256-stHjJeafcffHjllD1BDmULRwe7DvMuTd89o39UF26Io=";
      };

      doCheck = false;

      meta = with lib; {
        description = "Typing stubs for certifi";
        homepage = "https://github.com/python/typeshed";
        license = licenses.asl20;
      };
    };

    synchronicity = pythonBase.pkgs.buildPythonPackage {
      pname = "synchronicity";
      version = "0.12.5";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/s/synchronicity/synchronicity-0.12.5.tar.gz";
        sha256 = "sha256-lNlrHYVpjjBWuWp5O4wJSa9lhOSn2Hf6vetThe/iMKo=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        hatchling
      ];
      propagatedBuildInputs = with pythonBase.pkgs; [
        typing-extensions
      ];

      doCheck = false;

      pythonImportsCheck = [ "synchronicity" ];

      meta = with lib; {
        description = "Primitives for managing the synchronicity of Python code";
        homepage = "https://github.com/modal-labs/synchronicity";
        license = licenses.asl20;
      };
    };

    modal = pythonBase.pkgs.buildPythonPackage {
      pname = "modal";
      version = "1.5.5";
      format = "wheel";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/04/19/b3dca8baec119126058b12ca620e44022e4d08a091956668bd04180c89a7/modal-1.5.5-py3-none-any.whl";
        sha256 = "sha256-jRDT7gmBiquhlztzziUhq4lhtjoptbUuP/DSXnp0gI4=";
      };

      propagatedBuildInputs =
        with pythonBase.pkgs;
        [
          aiohttp
          cbor2
          certifi
          click
          grpclib
          protobuf
          rich
          toml
          typer
          watchfiles
          typing-extensions
          types-toml
        ]
        ++ [
          pythonPackages.synchronicity
          pythonPackages.types-certifi
        ];

      doCheck = false;

      # modal pins protobuf<7 but nixpkgs ships protobuf 7.x; the wheel works
      # fine in practice, so relax the runtime dep check.
      pythonRelaxDeps = [ "protobuf" ];

      pythonImportsCheck = [ "modal" ];

      meta = with lib; {
        description = "Python client library for Modal";
        homepage = "https://github.com/modal-labs/modal-client";
        license = licenses.asl20;
      };
    };

    scrapy-playwright = pythonBase.pkgs.buildPythonPackage {
      pname = "scrapy-playwright";
      version = "0.0.48";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/s/scrapy_playwright/scrapy_playwright-0.0.48.tar.gz";
        sha256 = "sha256-Ymd5qovKzWHuvD4h42LGLLta518WiiVIhfH3ypto2dI=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        setuptools
        wheel
      ];

      propagatedBuildInputs = with pythonBase.pkgs; [
        scrapy
        playwright
      ];

      doCheck = false;

      pythonImportsCheck = [ "scrapy_playwright" ];

      meta = with lib; {
        description = "Scrapy with Playwright for JavaScript rendering";
        homepage = "https://github.com/scrapy-plugins/scrapy-playwright";
        license = licenses.bsd2;
      };
    };

    scrapfly-sdk = pythonBase.pkgs.buildPythonPackage {
      pname = "scrapfly-sdk";
      version = "0.12.0";
      format = "setuptools";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/s/scrapfly_sdk/scrapfly_sdk-0.12.0.tar.gz";
        sha256 = "sha256-x7NtZh5Fx4+W0oUWe7EhHES9/N/B8JnjGC2xZndBgMs=";
      };

      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs; [
        backoff
        decorator
        loguru
        python-dateutil
        requests
        urllib3
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = [ "scrapfly" ];

      meta = with lib; {
        description = "Scrapfly SDK for Scrapfly";
        homepage = "https://github.com/scrapfly/python-sdk";
        license = licenses.mit;
      };
    };
  };
in
pythonPackages
