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
    rev = "560a16640dc3d32ae754114a1643d4f51efebae0";
    hash = "sha256-fe7X9vISF0wN1DMJYlhZCuCIb37g/0vV45kfX75DTC4=";
  };

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
      pkgs.unstable.python313Packages.iterfzf
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
