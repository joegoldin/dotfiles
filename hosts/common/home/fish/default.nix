{
  pkgs,
  lib,
  config,
  ...
}:
let
  fishAiSrc = pkgs.fetchFromGitHub {
    owner = "joegoldin";
    repo = "fish-ai";
    rev = "fdd94b8176b4b538fb424caabd97e636dd620d93";
    hash = "sha256-7e0so3EXgjqfi6b1H7LIa0y+p2ZwV1lYwK6mrqwMbSI=";
  };

  # Override iterfzf to 1.9.0 within stable python set (fish-ai needs read0 param)
  iterfzf-1_9 = pkgs.python313Packages.iterfzf.overridePythonAttrs (old: rec {
    version = "1.9.0.67.0";
    src = pkgs.fetchFromGitHub {
      owner = "dahlia";
      repo = "iterfzf";
      tag = version;
      hash = "sha256-Giw5d0X8/1PXK1j428LJjg+Gqadm93C51mLfrYc5J94=";
    };
  });

  fishAiPython = pkgs.python313Packages.buildPythonApplication {
    pname = "fish-ai";
    version = "2.10.2";
    src = fishAiSrc;
    pyproject = true;

    nativeBuildInputs = with pkgs.python313Packages; [
      setuptools
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = true;
    pythonRemoveDeps = [ "mistralai" ];

    propagatedBuildInputs = with pkgs.python313Packages; [
      openai
      simple-term-menu
      iterfzf-1_9
      binaryornot
      anthropic
      cohere
      keyring
      groq
      google-genai
      httpx
    ];

    # Tests require network access
    doCheck = false;
  };

  # Wrap fish-ai binaries to inject ANTHROPIC_API_KEY from agenix at runtime
  fishAiPythonWrapped = pkgs.symlinkJoin {
    name = "fish-ai-wrapped-${fishAiPython.version}";
    paths = [ fishAiPython ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for f in $out/bin/*; do
        wrapProgram "$f" \
          --run 'export ANTHROPIC_API_KEY=$(cat /run/agenix/anthropic_api_key 2>/dev/null || true)'
      done
    '';
  };
in
{
  programs.fish = {
    enable = true;
    inherit ((import ./init.nix { inherit pkgs config; })) interactiveShellInit;
    functions = import ./functions.nix;
    inherit ((import ./plugins.nix { inherit pkgs fishAiSrc; })) plugins;
    inherit ((import ./aliases.nix { inherit lib config; })) shellAbbrs;
    inherit ((import ./aliases.nix { inherit lib config; })) shellAliases;
  };

  programs.atuin = import ./atuin.nix { inherit pkgs config; };

  # Symlink the Nix-built fish-ai Python env to where the plugin expects it
  xdg.dataFile."fish-ai".source = lib.mkIf (
    pkgs.stdenv.hostPlatform.system == "x86_64-linux"
  ) fishAiPythonWrapped;

  # Clean up any old venv that was manually installed
  home.activation.fishAiCleanup = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") (
    lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      INSTALL_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/fish-ai"
      if [ -d "$INSTALL_DIR" ] && [ ! -L "$INSTALL_DIR" ]; then
        echo "Removing old fish-ai venv (now managed by Nix)..."
        rm -rf "$INSTALL_DIR"
      fi
    ''
  );
}
