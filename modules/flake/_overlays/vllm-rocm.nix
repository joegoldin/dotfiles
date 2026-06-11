# vLLM ROCm build fixes overlay
#
# Exposes a top-level `vllm-rocm` Python application (alongside upstream
# `vllm`). We deliberately do NOT override `python3` or `python3Packages` —
# overriding the package set re-derives its identity, which cascades a rebuild
# across every python package in the closure (torch, transformers, datasets,
# everything that consumes `python3Packages`). Patching vllm and xgrammar as
# isolated leaves keeps `unstable.python3Packages.*` at upstream hashes so
# attic / cache.nixos.org substitutes keep hitting.
#
# rocmSupport for torch etc. continues to come from
# `nixpkgs.config.rocmSupport = true` in flake.nix — that is independent of
# this overlay.
final: prev:
let
  inherit (final) lib;
  py = prev.python3Packages;

  tritonKernelsSrc = final.fetchFromGitHub {
    owner = "triton-lang";
    repo = "triton";
    tag = "v3.5.0";
    hash = "sha256-F6T0n37Lbs+B7UHNYzoIQHjNNv3TcMtoXjNrT8ZUlxY=";
  };

  # Torch's C++ headers include `thrust/complex.h` when built with ROCm,
  # but rocThrust isn't reliably pulled into the compile include path.
  rocmThrustIncludeTree = final.symlinkJoin {
    name = "vllm-rocm-thrust-includes";
    paths = with final.rocmPackages; [
      rocthrust
      rocprim
      hipcub
    ];
  };

  # xgrammar: test_structural_tag_converter needs HuggingFace network access.
  # Isolated override — not added to python3Packages, so the upstream xgrammar
  # still exists at its cached hash for anything else that might consume it.
  xgrammar' = py.xgrammar.overrideAttrs (old: {
    disabledTestPaths = (old.disabledTestPaths or [ ]) ++ [
      "tests/python/test_structural_tag_converter.py"
    ];
  });

  # vllm: pin our patched xgrammar as input, add ROCm build deps, thrust
  # includes, and pre-fetched triton kernels.
  vllm' =
    (py.vllm.override {
      xgrammar = xgrammar';
    }).overrideAttrs
      (old: {
        buildInputs =
          (old.buildInputs or [ ])
          ++ (with final.rocmPackages; [
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
          (lib.cmakeFeature "CMAKE_CXX_FLAGS" "-I${rocmThrustIncludeTree}/include")
          (lib.cmakeFeature "CMAKE_HIP_FLAGS" "-I${rocmThrustIncludeTree}/include")
        ];
        env = (old.env or { }) // {
          ROCM_PATH = "${final.rocmPackages.clr}";
          ROCM_HOME = "${final.rocmPackages.clr}";
          TRITON_KERNELS_SRC_DIR = "${lib.getDev tritonKernelsSrc}/python/triton_kernels/triton_kernels";
        };
        # tensorizer, runai-model-streamer, conch-triton-kernels not in nixpkgs
        dontCheckRuntimeDeps = true;
      });
in
{
  vllm-rocm = py.toPythonApplication vllm';
}
