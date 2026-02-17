# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });

    howdy = prev.howdy.overrideAttrs (oldAttrs: {
      patches =
        (oldAttrs.patches or [])
        ++ [
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
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
      config.android_sdk.accept_license = true;
    };
  };

  # LLM agent packages (claude-code, codex, gemini-cli) available as pkgs.llm-agents.*
  llm-agents-packages = inputs.llm-agents.overlays.default;

  # MCP server packages for declarative MCP configuration
  # The upstream overlay only exports github-mcp-server; we also need mcp-language-server
  mcps-packages = final: prev:
    (inputs.mcps.overlays.default final prev)
    // {
      mcp-language-server = inputs.mcps.packages.${final.stdenv.hostPlatform.system}.mcp-language-server;
      mcp-nixos = inputs.mcps.inputs.mcp-nixos.packages.${final.stdenv.hostPlatform.system}.default;
    };
}
