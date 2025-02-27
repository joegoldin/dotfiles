{
  pkgs,
  lib,
  pythonBase,
  unstable,
  ...
}: {
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
      click-completion
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

  # Note, these are available in nixpkgs unstable, but are still behind the latest versions
  llm-anthropic = pythonBase.pkgs.buildPythonPackage rec {
    pname = "llm-anthropic";
    version = "0.14";
    format = "pyproject";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/source/l/llm_anthropic/llm_anthropic-0.14.tar.gz";
      sha256 = "sha256-SNTyBJM+kFJoIz4gh+Dl7MrQ4yJVyvwNv38va/wBgb4=";
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
    version = "0.12";
    format = "pyproject";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/source/l/llm_gemini/llm_gemini-0.12.tar.gz";
      sha256 = "sha256-Ugur1VLjdbc18OvCDc9uVkx7j0+u2WIUXz8xNdm55vE=";
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
    version = "0.1";
    format = "pyproject";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/source/l/llm_grok/llm_grok-0.1.tar.gz";
      sha256 = "sha256-25+fIKgV+AWSpwqFiv1GfdZZF9/QqF9zFDuTqCBkBiE=";
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

  llm-ollama = pythonBase.pkgs.buildPythonPackage rec {
    pname = "llm-ollama";
    version = "0.8.2";
    format = "pyproject";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/source/l/llm_ollama/llm_ollama-0.8.2.tar.gz";
      sha256 = "sha256-cvZ6AdzLsMPl6BHsHmYYYc7Ab0N6Ngrvc6frQzBpwHg=";
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
    version = "2025.2.2";
    format = "pyproject";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/source/l/llm_perplexity/llm_perplexity-2025.2.2.tar.gz";
      sha256 = "sha256-Sc577vi7kRaphC0wxQxfQX1sLSD8vih1UG7DSq9mpKk=";
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
}
