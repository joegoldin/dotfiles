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
    rev = "4b39b8aa04341322d3f9a1c11a14ca5800b71d28";
    hash = "sha256-E3/uRDNwn3tlXaUBKCGdPaWh93QNxF3cjZxplzYAgIo=";
  };

  fishAiPython = pkgs.python313Packages.buildPythonApplication {
    pname = "fish-ai";
    version = "2.7.2";
    src = fishAiSrc;
    pyproject = true;

    nativeBuildInputs = with pkgs.python313Packages; [
      setuptools
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = true;

    propagatedBuildInputs = with pkgs.python313Packages; [
      openai
      simple-term-menu
      iterfzf
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
  ) fishAiPython;

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
