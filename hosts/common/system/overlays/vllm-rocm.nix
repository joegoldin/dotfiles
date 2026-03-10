# vLLM ROCm build fixes overlay
# Patches vllm and xgrammar to build with ROCm support in the Nix sandbox
final: prev:
let
  inherit (final) lib;

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
in
{
  python3 = prev.python3.override {
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
    };
  };
  python3Packages = final.python3.pkgs;

  vllm = with final.python3Packages; toPythonApplication vllm;
}
