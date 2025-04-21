{
  pkgs,
  lib,
  pythonBase,
  unstable,
  ...
}: let
  # Define all packages in a recursive attribute set
  pythonPackages = rec {
    fal-client = pythonBase.pkgs.buildPythonPackage rec {
      pname = "fal-client";
      version = "0.5.9";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/f/fal_client/fal_client-0.5.9.tar.gz";
        sha256 = "sha256-I4pTACk9jY2hIE9EVdx4sVOfL/IBIvhw5ygMzCnyiSI=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        setuptools
        wheel
        setuptools-scm
      ];
      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs; [
        httpx
        httpx-sse
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = ["fal_client"];

      meta = with lib; {
        description = "Python client for fal.ai";
        homepage = "https://fal.ai";
        license = licenses.asl20;
      };
    };

    llm = pythonBase.pkgs.buildPythonPackage rec {
      pname = "llm";
      version = "0.24.2";
      format = "setuptools";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/l/llm/llm-0.24.2.tar.gz";
        sha256 = "sha256-4U8nIhg4hM4JaSIBtUzdlhlCSS8Nk8p0mmLQKzuL9Do=";
      };

      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs; [
        pyyaml
        click
        click-default-group
        condense-json
        openai
        pip
        pluggy
        puremagic
        pydantic
        python-ulid
        setuptools
        sqlite-migrate
        sqlite-utils
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = ["llm"];

      meta = with lib; {
        description = "CLI utility and Python library for interacting with Large Language Models from organizations like OpenAI, Anthropic and Gemini plus local models installed on your own machine.";
        homepage = "https://github.com/simonw/llm";
        license = licenses.asl20;
      };
    };

    # Note, these are available in nixpkgs unstable, but are still behind the latest versions
    llm-anthropic = pythonBase.pkgs.buildPythonPackage rec {
      pname = "llm-anthropic";
      version = "0.15.1";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/l/llm_anthropic/llm_anthropic-0.15.1.tar.gz";
        sha256 = "sha256-C8xNs4oS51YxAn1iJkk8j4sJ5dO0pVOwIiP4mv/MnQk=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs; [
        unstable.python312Packages.anthropic
        unstable.llm
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = ["llm_anthropic"];

      meta = with lib; {
        description = "LLM access to models by Anthropic, including the Claude series";
        homepage = "https://github.com/simonw/llm-anthropic";
        license = licenses.asl20;
      };
    };

    llm-cmd-comp = pythonBase.pkgs.buildPythonPackage rec {
      pname = "llm-cmd-comp";
      version = "1.1.1";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/l/llm_cmd_comp/llm_cmd_comp-1.1.1.tar.gz";
        sha256 = "sha256-YyqVN53AG8C41UlX3zY8Lv+ApueCorNUZUalf87Rht8=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs; [
        unstable.llm
        prompt-toolkit
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = ["llm_cmd_comp"];

      meta = with lib; {
        description = "Use LLM to generate commands for your shell";
        homepage = "https://github.com/CGamesPlay/llm-cmd-comp";
        license = licenses.asl20;
      };
    };

    llm-cmd = pythonBase.pkgs.buildPythonPackage rec {
      pname = "llm-cmd";
      version = "0.2a0";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/l/llm_cmd/llm_cmd-0.2a0.tar.gz";
        sha256 = "sha256-70NpDTtKmjfvt6ocmY1MoYB94HWnB8CtaWzlXGFLqKI=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs; [
        unstable.llm
        prompt-toolkit
        pygments
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = ["llm_cmd"];

      meta = with lib; {
        description = "Use LLM to generate and execute commands in your shell";
        homepage = "https://github.com/simonw/llm-cmd";
        license = licenses.asl20;
      };
    };

    llm-deepseek = pythonBase.pkgs.buildPythonPackage rec {
      pname = "llm-deepseek";
      version = "0.1.6";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/l/llm_deepseek/llm_deepseek-0.1.6.tar.gz";
        sha256 = "sha256-h6e06MYQmKXko5P+q7CnQn5x60+iino+1ZYNfjffi4M=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs; [
        unstable.llm
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = ["llm_deepseek"];

      meta = with lib; {
        description = "Access deepseek.com models via API";
        homepage = "https://github.com/abrasumente233/llm-deepseek";
        license = licenses.asl20;
      };
    };

    llm-gemini = pythonBase.pkgs.buildPythonPackage rec {
      pname = "llm-gemini";
      version = "0.18.1";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/l/llm_gemini/llm_gemini-0.18.1.tar.gz";
        sha256 = "sha256-GZ1PpGO3bSLZ/gIlequIEhduwUB0D5KKnuY7xqU+KkE=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs; [
        httpx
        ijson
        unstable.llm
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = ["llm_gemini"];

      meta = with lib; {
        description = "LLM plugin to access Google's Gemini family of models";
        homepage = "https://github.com/simonw/llm-gemini";
        license = licenses.asl20;
      };
    };

    llm-grok = pythonBase.pkgs.buildPythonPackage rec {
      pname = "llm-grok";
      version = "1.0";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/l/llm_grok/llm_grok-1.0.tar.gz";
        sha256 = "sha256-sKWpAQydqQBaBn+VMICQ4tLRJt13t7iIgz/Pmsucixc=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs; [
        httpx
        httpx-sse
        unstable.llm
        rich
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = ["llm_grok"];

      meta = with lib; {
        description = "LLM plugin providing access to Grok models using the xAI API";
        homepage = "https://github.com/hiepler/llm-grok";
        license = licenses.asl20;
      };
    };

    mlx = pythonBase.pkgs.buildPythonPackage rec {
      pname = "mlx";
      version = "0.25.0";
      format = "wheel";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/75/f3/fe19309ebcda6e34d14db5677e7862c5e5bfb4f539cd92ba0f37bc24097a/mlx-0.25.0-cp312-cp312-macosx_15_0_arm64.whl";
        sha256 = "sha256-+X0BisXlANqXz1hjEzL3GiMfH+6b925Cr0F3Gx6lQUk=";
      };

      # Dependencies
      propagatedBuildInputs = [];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = ["mlx"];

      meta = with lib; {
        description = "A framework for machine learning on Apple silicon.";
        homepage = "https://github.com/ml-explore/mlx";
        license = licenses.mit;
      };
    };

    mlx-lm = pythonBase.pkgs.buildPythonPackage rec {
      pname = "mlx-lm";
      version = "0.23.1";
      format = "setuptools";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/m/mlx_lm/mlx_lm-0.23.1.tar.gz";
        sha256 = "sha256-US4rMdo4GDKVRW3LMF5ds9aMN5D+PrW+5V4aHmI93lE=";
      };

      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs;
        [
          jinja2
          numpy
          protobuf
          pyyaml
          transformers
        ]
        ++ [
          pythonPackages.mlx
        ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = ["mlx_lm"];

      meta = with lib; {
        description = "LLMs on Apple silicon with MLX and the Hugging Face Hub";
        homepage = "https://github.com/ml-explore/mlx-lm";
        license = licenses.mit;
      };
    };

    llm-mlx = pythonBase.pkgs.buildPythonPackage rec {
      pname = "llm-mlx";
      version = "0.3";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/l/llm_mlx/llm_mlx-0.3.tar.gz";
        sha256 = "sha256-nKJIuWpwmfwU0L1DlTogLek3wlpxwq65BqYBvSgFynI=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = [
        pythonPackages.llm
        pythonPackages.mlx-lm
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = ["llm_mlx"];

      meta = with lib; {
        description = "Support for MLX models in LLM";
        homepage = "https://github.com/simonw/llm-mlx";
        license = licenses.asl20;
      };
    };

    llm-ollama = pythonBase.pkgs.buildPythonPackage rec {
      pname = "llm-ollama";
      version = "0.9.1";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/l/llm_ollama/llm_ollama-0.9.1.tar.gz";
        sha256 = "sha256-qw3ufbjjqLOrdPj9G5okGfXkAf36I6J+NbhLeZvY8hg=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs; [
        unstable.llm
        ollama
        pydantic
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = ["llm_ollama"];

      meta = with lib; {
        description = "LLM plugin providing access to local Ollama models";
        homepage = "https://github.com/taketwo/llm-ollama";
        license = licenses.asl20;
      };
    };

    llm-perplexity = pythonBase.pkgs.buildPythonPackage rec {
      pname = "llm-perplexity";
      version = "2025.2.3";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/l/llm_perplexity/llm_perplexity-2025.2.3.tar.gz";
        sha256 = "sha256-pu89viJqhRiCLyBZx+FFMVKRUmEx8kbcalPBzz/Jxj8=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        setuptools
        wheel
      ];
      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs; [
        unstable.llm
        openai
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = ["llm_perplexity"];

      meta = with lib; {
        description = "LLM access to pplx-api 3 by Perplexity Labs";
        homepage = "https://github.com/hex/llm-perplexity";
        license = licenses.asl20;
      };
    };

    deepgram-sdk = pythonBase.pkgs.buildPythonPackage rec {
      pname = "deepgram-sdk";
      version = "3.10.1";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/d/deepgram_sdk/deepgram_sdk-3.10.1.tar.gz";
        sha256 = "sha256-JDhOn/6lvxsvi7MFw0txvra4xayg9V0BnryfUGr5L9A=";
      };

      nativeBuildInputs = with pythonBase.pkgs; [
        setuptools
        wheel
        poetry-core
      ];
      # Dependencies
      propagatedBuildInputs = with pythonBase.pkgs; [
        aenum
        aiofiles
        aiohttp
        dataclasses-json
        deprecation
        httpx
        typing-extensions
        websockets
      ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = ["deepgram"];

      meta = with lib; {
        description = "The official Python SDK for the Deepgram automated speech recognition platform.";
        homepage = "https://github.com/deepgram/deepgram-python-sdk";
        license = licenses.mit;
      };
    };
  };
in
  pythonPackages
