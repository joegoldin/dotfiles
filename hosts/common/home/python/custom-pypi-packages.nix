{
  pkgs,
  lib,
  pythonBase,
  ...
}:
let
  # Define all packages in a recursive attribute set
  pythonPackages = {
    fal-client = pythonBase.pkgs.buildPythonPackage {
      pname = "fal-client";
      version = "0.7.0";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/f/fal_client/fal_client-0.7.0.tar.gz";
        sha256 = "sha256-m/As/FasiVcVnoqVnvCMV+VhjOrCz/VS9yBDNjuSpy8=";
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
      pythonImportsCheck = [ "fal_client" ];

      meta = with lib; {
        description = "Python client for fal.ai";
        homepage = "https://fal.ai";
        license = licenses.asl20;
      };
    };

    # llm = pythonBase.pkgs.buildPythonPackage rec {
    #   pname = "llm";
    #   version = "0.26";
    #   format = "setuptools";

    #   src = pkgs.fetchurl {
    #     url = "https://files.pythonhosted.org/packages/source/l/llm/llm-0.26.tar.gz";
    #     sha256 = "sha256-wundvFgtoQxhESwPmDOD+g3HvuPKfW8q3hotADdx6xs=";
    #   };

    #   # Dependencies
    #   propagatedBuildInputs = with pythonBase.pkgs; [
    #     pyyaml
    #     click
    #     click-default-group
    #     condense-json
    #     openai
    #     pip
    #     pluggy
    #     puremagic
    #     pydantic
    #     python-ulid
    #     setuptools
    #     sqlite-migrate
    #     sqlite-utils
    #   ];

    #   # Disable tests - enable if you have specific test dependencies
    #   doCheck = false;

    #   # Basic import check
    #   pythonImportsCheck = ["llm"];

    #   meta = with lib; {
    #     description = "CLI utility and Python library for interacting with Large Language Models from organizations like OpenAI, Anthropic and Gemini plus local models installed on your own machine.";
    #     homepage = "https://github.com/simonw/llm";
    #     license = licenses.asl20;
    #   };
    # };

    # Note, these are available in nixpkgs unstable, but are still behind the latest versions
    # llm-anthropic = pythonBase.pkgs.buildPythonPackage rec {
    #   pname = "llm-anthropic";
    #   version = "0.17";
    #   format = "pyproject";

    #   src = pkgs.fetchurl {
    #     url = "https://files.pythonhosted.org/packages/source/l/llm_anthropic/llm_anthropic-0.17.tar.gz";
    #     sha256 = "sha256-L14atbfrmoS40HRzqGlwiLZZ/U8ZQdloY88Yz4z7nrA=";
    #   };

    #   nativeBuildInputs = with pythonBase.pkgs; [
    #     setuptools
    #     wheel
    #   ];
    #   # Dependencies
    #   propagatedBuildInputs = with pythonBase.pkgs; [
    #     unstable.python312Packages.anthropic
    #     unstable.llm
    #   ];

    #   # Disable tests - enable if you have specific test dependencies
    #   doCheck = false;

    #   # Basic import check
    #   pythonImportsCheck = ["llm_anthropic"];

    #   meta = with lib; {
    #     description = "LLM access to models by Anthropic, including the Claude series";
    #     homepage = "https://github.com/simonw/llm-anthropic";
    #     license = licenses.asl20;
    #   };
    # };

    # llm-cmd-comp = pythonBase.pkgs.buildPythonPackage rec {
    #   pname = "llm-cmd-comp";
    #   version = "1.2.0";
    #   format = "pyproject";

    #   src = pkgs.fetchurl {
    #     url = "https://files.pythonhosted.org/packages/source/l/llm_cmd_comp/llm_cmd_comp-1.2.0.tar.gz";
    #     sha256 = "sha256-bsczL/o4cXUgumCYGwQPF+TMTKT9jXFbcgra/NSngyM=";
    #   };

    #   nativeBuildInputs = with pythonBase.pkgs; [
    #     setuptools
    #     wheel
    #   ];
    #   # Dependencies
    #   propagatedBuildInputs = with pythonBase.pkgs; [
    #     unstable.llm
    #     prompt-toolkit
    #   ];

    #   # Disable tests - enable if you have specific test dependencies
    #   doCheck = false;

    #   # Basic import check
    #   pythonImportsCheck = ["llm_cmd_comp"];

    #   meta = with lib; {
    #     description = "Use LLM to generate commands for your shell";
    #     homepage = "https://github.com/CGamesPlay/llm-cmd-comp";
    #     license = licenses.asl20;
    #   };
    # };

    # llm-cmd = pythonBase.pkgs.buildPythonPackage rec {
    #   pname = "llm-cmd";
    #   version = "0.2a0";
    #   format = "pyproject";

    #   src = pkgs.fetchurl {
    #     url = "https://files.pythonhosted.org/packages/source/l/llm_cmd/llm_cmd-0.2a0.tar.gz";
    #     sha256 = "sha256-70NpDTtKmjfvt6ocmY1MoYB94HWnB8CtaWzlXGFLqKI=";
    #   };

    #   nativeBuildInputs = with pythonBase.pkgs; [
    #     setuptools
    #     wheel
    #   ];
    #   # Dependencies
    #   propagatedBuildInputs = with pythonBase.pkgs; [
    #     unstable.llm
    #     prompt-toolkit
    #     pygments
    #   ];

    #   # Disable tests - enable if you have specific test dependencies
    #   doCheck = false;

    #   # Basic import check
    #   pythonImportsCheck = ["llm_cmd"];

    #   meta = with lib; {
    #     description = "Use LLM to generate and execute commands in your shell";
    #     homepage = "https://github.com/simonw/llm-cmd";
    #     license = licenses.asl20;
    #   };
    # };

    # llm-deepseek = pythonBase.pkgs.buildPythonPackage rec {
    #   pname = "llm-deepseek";
    #   version = "0.1.6";
    #   format = "pyproject";

    #   src = pkgs.fetchurl {
    #     url = "https://files.pythonhosted.org/packages/source/l/llm_deepseek/llm_deepseek-0.1.6.tar.gz";
    #     sha256 = "sha256-h6e06MYQmKXko5P+q7CnQn5x60+iino+1ZYNfjffi4M=";
    #   };

    #   nativeBuildInputs = with pythonBase.pkgs; [
    #     setuptools
    #     wheel
    #   ];
    #   # Dependencies
    #   propagatedBuildInputs = with pythonBase.pkgs; [
    #     unstable.llm
    #   ];

    #   # Disable tests - enable if you have specific test dependencies
    #   doCheck = false;

    #   # Basic import check
    #   pythonImportsCheck = ["llm_deepseek"];

    #   meta = with lib; {
    #     description = "Access deepseek.com models via API";
    #     homepage = "https://github.com/abrasumente233/llm-deepseek";
    #     license = licenses.asl20;
    #   };
    # };

    # llm-gemini = pythonBase.pkgs.buildPythonPackage rec {
    #   pname = "llm-gemini";
    #   version = "0.24";
    #   format = "pyproject";

    #   src = pkgs.fetchurl {
    #     url = "https://files.pythonhosted.org/packages/source/l/llm_gemini/llm_gemini-0.24.tar.gz";
    #     sha256 = "sha256-goN4T15M0COa4L1A5jGrNZX5pRRbLFqxcOSc9aHSiv8=";
    #   };

    #   nativeBuildInputs = with pythonBase.pkgs; [
    #     setuptools
    #     wheel
    #   ];
    #   # Dependencies
    #   propagatedBuildInputs = with pythonBase.pkgs; [
    #     httpx
    #     ijson
    #     unstable.llm
    #   ];

    #   # Disable tests - enable if you have specific test dependencies
    #   doCheck = false;

    #   # Basic import check
    #   pythonImportsCheck = ["llm_gemini"];

    #   meta = with lib; {
    #     description = "LLM plugin to access Google's Gemini family of models";
    #     homepage = "https://github.com/simonw/llm-gemini";
    #     license = licenses.asl20;
    #   };
    # };

    # llm-grok = pythonBase.pkgs.buildPythonPackage rec {
    #   pname = "llm-grok";
    #   version = "1.2.0";
    #   format = "pyproject";

    #   src = pkgs.fetchurl {
    #     url = "https://files.pythonhosted.org/packages/source/l/llm_grok/llm_grok-1.2.0.tar.gz";
    #     sha256 = "sha256-l/mPBSOlrHwJKuOQtRTqivu+ZwE6Y+sHPYcbO6RU1/Y=";
    #   };

    #   nativeBuildInputs = with pythonBase.pkgs; [
    #     setuptools
    #     wheel
    #   ];
    #   # Dependencies
    #   propagatedBuildInputs = with pythonBase.pkgs; [
    #     httpx
    #     httpx-sse
    #     unstable.llm
    #     rich
    #   ];

    #   # Disable tests - enable if you have specific test dependencies
    #   doCheck = false;

    #   # Basic import check
    #   pythonImportsCheck = ["llm_grok"];

    #   meta = with lib; {
    #     description = "LLM plugin providing access to Grok models using the xAI API";
    #     homepage = "https://github.com/hiepler/llm-grok";
    #     license = licenses.asl20;
    #   };
    # };

    mlx = pythonBase.pkgs.buildPythonPackage {
      pname = "mlx";
      version = "0.26.5";
      format = "wheel";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/52/c1/8193c3adb61debec85d72cd9315c0e753f4ffd64ff2a4000e0e7f1e2b001/mlx-0.26.5-cp312-cp312-macosx_15_0_arm64.whl";
        sha256 = "sha256-d8W3ULJKGO1uQz3EbXhxk7EkqGmxtl0VMr+3037HFy8=";
      };

      # Dependencies
      propagatedBuildInputs = [ ];

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = [ "mlx" ];

      meta = with lib; {
        description = "A framework for machine learning on Apple silicon.";
        homepage = "https://github.com/ml-explore/mlx";
        license = licenses.mit;
      };
    };

    # mlx-lm = pythonBase.pkgs.buildPythonPackage rec {
    #   pname = "mlx-lm";
    #   version = "0.26.0";
    #   format = "setuptools";

    #   src = pkgs.fetchurl {
    #     url = "https://files.pythonhosted.org/packages/source/m/mlx_lm/mlx_lm-0.26.0.tar.gz";
    #     sha256 = "sha256-eJgK2ZS6+XZ3nMHDTA1Vwca2Pf/vSJnWf+wkDQxEO1I=";
    #   };

    #   # Dependencies
    #   propagatedBuildInputs = with pythonBase.pkgs;
    #     [
    #       jinja2
    #       numpy
    #       protobuf
    #       pyyaml
    #       transformers
    #     ]
    #     ++ [
    #       pythonPackages.mlx
    #     ];

    #   # Disable tests - enable if you have specific test dependencies
    #   doCheck = false;

    #   # Basic import check
    #   pythonImportsCheck = ["mlx_lm"];

    #   meta = with lib; {
    #     description = "LLMs on Apple silicon with MLX and the Hugging Face Hub";
    #     homepage = "https://github.com/ml-explore/mlx-lm";
    #     license = licenses.mit;
    #   };
    # };

    # llm-mlx = pythonBase.pkgs.buildPythonPackage rec {
    #   pname = "llm-mlx";
    #   version = "0.4";
    #   format = "pyproject";

    #   src = pkgs.fetchurl {
    #     url = "https://files.pythonhosted.org/packages/source/l/llm_mlx/llm_mlx-0.4.tar.gz";
    #     sha256 = "sha256-7jsfsgPJvxj+aks52Kh4eilnQpECuq9R822AkKmyV7o=";
    #   };

    #   nativeBuildInputs = with pythonBase.pkgs; [
    #     setuptools
    #     wheel
    #   ];
    #   # Dependencies
    #   propagatedBuildInputs = [
    #     pythonPackages.llm
    #     pythonPackages.mlx-lm
    #   ];

    #   # Disable tests - enable if you have specific test dependencies
    #   doCheck = false;

    #   # Basic import check
    #   pythonImportsCheck = ["llm_mlx"];

    #   meta = with lib; {
    #     description = "Support for MLX models in LLM";
    #     homepage = "https://github.com/simonw/llm-mlx";
    #     license = licenses.asl20;
    #   };
    # };

    # llm-ollama = pythonBase.pkgs.buildPythonPackage rec {
    #   pname = "llm-ollama";
    #   version = "0.12.0";
    #   format = "pyproject";

    #   src = pkgs.fetchurl {
    #     url = "https://files.pythonhosted.org/packages/source/l/llm_ollama/llm_ollama-0.12.0.tar.gz";
    #     sha256 = "sha256-lDDQTLmDDp4+GQvZTzlA304xABWymhjgc2xJu3Z2l6U=";
    #   };

    #   nativeBuildInputs = with pythonBase.pkgs; [
    #     setuptools
    #     wheel
    #   ];
    #   # Dependencies
    #   propagatedBuildInputs = with pythonBase.pkgs; [
    #     unstable.llm
    #     ollama
    #     pydantic
    #   ];

    #   # Disable tests - enable if you have specific test dependencies
    #   doCheck = false;

    #   # Basic import check
    #   pythonImportsCheck = ["llm_ollama"];

    #   meta = with lib; {
    #     description = "LLM plugin providing access to local Ollama models";
    #     homepage = "https://github.com/taketwo/llm-ollama";
    #     license = licenses.asl20;
    #   };
    # };

    # llm-perplexity = pythonBase.pkgs.buildPythonPackage rec {
    #   pname = "llm-perplexity";
    #   version = "2025.6.0";
    #   format = "pyproject";

    #   src = pkgs.fetchurl {
    #     url = "https://files.pythonhosted.org/packages/source/l/llm_perplexity/llm_perplexity-2025.6.0.tar.gz";
    #     sha256 = "sha256-XzetzZSsimV8OEoGp8glO7KSj06fFQihr4uQTjQOxoA=";
    #   };

    #   nativeBuildInputs = with pythonBase.pkgs; [
    #     setuptools
    #     wheel
    #   ];
    #   # Dependencies
    #   propagatedBuildInputs = with pythonBase.pkgs; [
    #     unstable.llm
    #     openai
    #   ];

    #   # Disable tests - enable if you have specific test dependencies
    #   doCheck = false;

    #   # Basic import check
    #   pythonImportsCheck = ["llm_perplexity"];

    #   meta = with lib; {
    #     description = "LLM access to pplx-api 3 by Perplexity Labs";
    #     homepage = "https://github.com/hex/llm-perplexity";
    #     license = licenses.asl20;
    #   };
    # };

    deepgram-sdk = pythonBase.pkgs.buildPythonPackage {
      pname = "deepgram-sdk";
      version = "4.7.0";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/d/deepgram_sdk/deepgram_sdk-4.7.0.tar.gz";
        sha256 = "sha256-43E5bYg11El4LfRyw71QH2ytQbPJJfZncZM/8/xLGhM=";
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
      pythonImportsCheck = [ "deepgram" ];

      meta = with lib; {
        description = "The official Python SDK for the Deepgram automated speech recognition platform.";
        homepage = "https://github.com/deepgram/deepgram-python-sdk";
        license = licenses.mit;
      };
    };

    lmstudio = pythonBase.pkgs.buildPythonPackage {
      pname = "lmstudio";
      version = "1.4.1";
      format = "pyproject";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/l/lmstudio/lmstudio-1.4.1.tar.gz";
        sha256 = "sha256-UzoCgAZxH0OqgRjePLmjIlkBqz2m6KgUG7S74VQ4zMA=";
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
    scrapfly-sdk = pythonBase.pkgs.buildPythonPackage {
      pname = "scrapfly-sdk";
      version = "0.8.23";
      format = "setuptools";

      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/source/s/scrapfly_sdk/scrapfly_sdk-0.8.23.tar.gz";
        sha256 = "sha256-Jmj3qCvzprJAvi8eQJDPFA10GB3le7RlQ3GVVPvtVa4=";
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
