# This file defines overlays
{ inputs, ... }:
let
  # Common overlays applied to the unstable nixpkgs import.
  # Host-specific unstable overrides (e.g. for rocmSupport) should include these
  # to avoid losing package patches.
  unstableOverlays = [
    inputs.tinygrad-nix.overlays.default
    (uFinal: uPrev: {
      pulsemeeter = uPrev.pulsemeeter.overrideAttrs (oldAttrs: {
        src = uPrev.fetchFromGitHub {
          owner = "joegoldin";
          repo = "pulsemeeter";
          rev = "b87dd7f220e18f21795e1b718290c986b19c4907";
          hash = "sha256-B3wbAxL+6Tw83BwwvbGz4I+ZhaZSFpus/qlbxi9w8mw=";
        };
        patches = [ ];
      });

      # ibis-framework: duckdb import fails during pythonImportsCheck in nixpkgs
      python313Packages = uPrev.python313Packages.overrideScope (pyFinal: pyPrev: {
        ibis-framework = pyPrev.ibis-framework.overrideAttrs (old: {
          doInstallCheck = false;
          pythonImportsCheck = [ ];
        });
      });
    })
  ];
in
{
  inherit unstableOverlays;

  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });

    # direnv: fish integration test gets SIGKILL in the nix sandbox
    direnv = prev.direnv.overrideAttrs (old: {
      doCheck = false;
    });

    # Force freerdp to use ffmpeg for H.264 instead of broken openh264
    freerdp = prev.freerdp.override { openh264 = null; };

    howdy = prev.howdy.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or [ ]) ++ [
        (final.fetchpatch {
          url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/216245.patch";
          hash = "sha256-0N8xyCConfOfCNzSnoCHGlCSv6GQfpUQIwb/W5eQA0U=";
        })
      ];
    });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
      };
      overlays = unstableOverlays;
    };
  };

  # tinygrad with ROCm/CUDA/OpenCL support
  tinygrad-packages = inputs.tinygrad-nix.overlays.default;

  # Claude Desktop for Linux
  claude-desktop-packages = inputs.claude-desktop-debian.overlays.default;

  # LLM agent packages (claude-code, codex, gemini-cli) available as pkgs.llm-agents.*
  llm-agents-packages = inputs.llm-agents.overlays.default;

  # audiomemo (recording + transcription CLI)
  audiomemo-packages = inputs.audiomemo.overlays.default;

  # claude-container (claude-code wrapper in docker container with sandboxing)
  claude-container-packages = inputs.claude-container.overlays.default;

  # MCP server packages for declarative MCP configuration
  # The upstream overlay only exports github-mcp-server; we also need mcp-language-server
  # Inlined upstream overlay to avoid deprecated pkgs.system access in mcps.overlays.default
  mcps-packages =
    final: _prev:
    let
      unstable-pkgs = import inputs.mcps.inputs.nixpkgs-unstable {
        inherit (final.stdenv.hostPlatform) system;
      };
    in
    {
      inherit (unstable-pkgs) github-mcp-server;
      inherit (inputs.mcps.packages.${final.stdenv.hostPlatform.system}) mcp-language-server;
      mcp-nixos = inputs.mcps.inputs.mcp-nixos.packages.${final.stdenv.hostPlatform.system}.default;
    };
}
