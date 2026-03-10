# This file defines overlays
{ inputs, ... }:
{
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
        rocmSupport = true;
      };
      overlays = [
        # (import ./vllm-rocm.nix)

        # Temporary build fixes until upstream nixpkgs resolves these
        (
          xFinal: xPrev:
          let
            tritonKernelsSrc = xFinal.fetchFromGitHub {
              owner = "triton-lang";
              repo = "triton";
              tag = "v3.5.0";
              hash = "sha256-F6T0n37Lbs+B7UHNYzoIQHjNNv3TcMtoXjNrT8ZUlxY=";
            };
            # Torch's C++ headers include `thrust/complex.h` when built with ROCm,
            # but rocThrust isn't reliably pulled into the compile include path.
            rocmThrustIncludeTree = xFinal.symlinkJoin {
              name = "vllm-rocm-thrust-includes";
              paths = with xFinal.rocmPackages; [
                rocthrust
                rocprim
                hipcub
              ];
            };
          in
          {
            python3 = xPrev.python3.override {
              packageOverrides = pyFinal: pyPrev: {
                # xgrammar: test_structural_tag_converter needs HuggingFace network access
                xgrammar = pyPrev.xgrammar.overrideAttrs (old: {
                  disabledTestPaths = (old.disabledTestPaths or [ ]) ++ [
                    "tests/python/test_structural_tag_converter.py"
                  ];
                });

                # vllm: set ROCM_PATH, add ROCm build deps, thrust includes, and pre-fetch triton kernels
                vllm = pyPrev.vllm.overrideAttrs (old: {
                  buildInputs =
                    (old.buildInputs or [ ])
                    ++ (with xFinal.rocmPackages; [
                      rocrand
                      hiprand
                      rocblas
                      miopen
                      hipfft
                      hipcub
                      hipsolver
                      rocsolver
                      hipblaslt
                      rocm-runtime
                    ]);
                  cmakeFlags = (old.cmakeFlags or [ ]) ++ [
                    (xFinal.lib.cmakeFeature "CMAKE_CXX_FLAGS" "-I${rocmThrustIncludeTree}/include")
                    (xFinal.lib.cmakeFeature "CMAKE_HIP_FLAGS" "-I${rocmThrustIncludeTree}/include")
                  ];
                  env = (old.env or { }) // {
                    ROCM_PATH = "${xFinal.rocmPackages.clr}";
                    ROCM_HOME = "${xFinal.rocmPackages.clr}";
                    TRITON_KERNELS_SRC_DIR = "${xFinal.lib.getDev tritonKernelsSrc}/python/triton_kernels/triton_kernels";
                  };
                  # tensorizer, runai-model-streamer, conch-triton-kernels not in nixpkgs
                  dontCheckRuntimeDeps = true;
                });
              };
            };
            python3Packages = xFinal.python3.pkgs;
          }
        )
      ];
    };
  };

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
