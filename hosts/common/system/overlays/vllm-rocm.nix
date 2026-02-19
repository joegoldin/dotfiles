# vLLM ROCm build fixes overlay
# Incorporates fixes from nixpkgs PR #487987 and patterns from github:Wulfsta/vllm-flake
# Targets gfx1201 (RDNA 4 / RX 9070 series)
final: prev:
let
  inherit (final) lib;
  inherit (final) rocmPackages;

  # Torch's C++ headers include `thrust/complex.h` when built with ROCm, but
  # rocThrust isn't reliably pulled into the compile include path.
  rocmThrustIncludeTree = final.symlinkJoin {
    name = "vllm-rocm-thrust-includes";
    paths = with rocmPackages; [
      rocthrust
      rocprim
      hipcub
    ];
  };

  # `setup.py` consumes `cmakeFlags` via Python's `str.split()`, so we must avoid spaces here.
  rocmExtraIncludeFlags = "-I${rocmThrustIncludeTree}/include";

  # Triton kernels source for ROCm builds (matches what upstream uses for CUDA)
  tritonKernelsSrc = final.fetchFromGitHub {
    owner = "triton-lang";
    repo = "triton";
    tag = "v3.5.0";
    hash = "sha256-F6T0n37Lbs+B7UHNYzoIQHjNNv3TcMtoXjNrT8ZUlxY=";
  };

  # Flash Attention with Composable Kernel (CK) support for gfx12 (RDNA 4)
  # https://github.com/hyoon1/flash-attention/tree/enable-ck-gfx12
  flashAttnCkSrc = final.fetchFromGitHub {
    owner = "hyoon1";
    repo = "flash-attention";
    rev = "enable-ck-gfx12";
    hash = "sha256-Y60NjI8jlqaR8ictZ5d8H4M+lSRk8gynN28fFz6+Jsw=";
  };
in
{
  # Restrict ROCm GPU targets to gfx1201 only (drastically reduces build time)
  rocmPackages = prev.rocmPackages.overrideScope (
    rFinal: rPrev: {
      clr = rPrev.clr.override {
        localGpuTargets = [ "gfx1201" ];
      };
      # composable_kernel conv instances only exist for gfx9 targets.
      # Add gfx90a as a build-only target so CK compiles; only gfx1201 kernels run at runtime.
      composable_kernel_base =
        (rPrev.composable_kernel_base.override {
          gpuTargets = [
            "gfx90a"
            "gfx1201"
          ];
        }).overrideAttrs
          {
            meta.broken = false;
          };
    }
  );

  # Override python3 to include the vllm ROCm build fixes
  python3 = prev.python3.override {
    packageOverrides = pyFinal: pyPrev: {
      # Flash Attention built from CK-gfx12 branch for RDNA 4 attention kernels
      flashAttnRocm = pyPrev.buildPythonPackage {
        pname = "flash-attn";
        version = "0-unstable-ck-gfx12";
        src = flashAttnCkSrc;
        format = "setuptools";

        nativeBuildInputs = [
          final.cmake
          final.ninja
          final.which
          rocmPackages.clr
        ];

        buildInputs = with rocmPackages; [
          clr
          rocm-runtime
        ];

        propagatedBuildInputs = with pyPrev; [
          torch
          einops
          packaging
        ];

        env = {
          PYTORCH_ROCM_ARCH = "gfx1201";
          ROCM_PATH = "${rocmPackages.clr}";
          ROCM_HOME = "${rocmPackages.clr}";
          FLASH_ATTENTION_TRITON_AMD_ENABLE = "TRUE";
          GPU_TARGETS = "gfx1201";
        };

        # CK kernel compilation is memory-intensive
        enableParallelBuilding = false;
        doCheck = false;
        dontCheckRuntimeDeps = true;
      };

      vllm = pyPrev.vllm.overrideAttrs (oldAttrs: {
        postPatch = (oldAttrs.postPatch or "") + ''
          # Fix cmake flags parsing to handle spaces correctly (nixpkgs PR #487987)
          substituteInPlace setup.py \
            --replace-fail 'import json' $'import json\nimport shlex' \
            --replace-fail 'os.environ.get("cmakeFlags", "").split()' 'shlex.split(os.environ.get("cmakeFlags", ""))'

          # Drop unavailable ROCm-specific Python requirements
          for pkg in pytest-asyncio tensorizer runai-model-streamer conch-triton-kernels grpcio-tools setuptools-scm; do
            sed -i "/$pkg/d" requirements/rocm.txt 2>/dev/null || true
          done
        '';

        buildInputs =
          (oldAttrs.buildInputs or [ ])
          ++ (with rocmPackages; [
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

        propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or [ ]) ++ [
          rocmPackages.amdsmi
          rocmPackages.rocminfo
          pyFinal.flashAttnRocm
          pyPrev.datasets
          pyPrev.peft
          pyPrev.timm
        ];

        cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
          (lib.cmakeFeature "CMAKE_CXX_FLAGS" rocmExtraIncludeFlags)
          (lib.cmakeFeature "CMAKE_HIP_FLAGS" rocmExtraIncludeFlags)
        ];

        env = (oldAttrs.env or { }) // {
          PYTORCH_ROCM_ARCH = "gfx1201";
          ROCM_PATH = "${rocmPackages.clr}";
          ROCM_HOME = "${rocmPackages.clr}";
          TRITON_KERNELS_SRC_DIR = "${lib.getDev tritonKernelsSrc}/python/triton_kernels/triton_kernels";
          FLASH_ATTENTION_TRITON_AMD_ENABLE = "TRUE";
        };

        makeWrapperArgs = (oldAttrs.makeWrapperArgs or [ ]) ++ [
          "--prefix"
          "PYTHONPATH"
          ":"
          "${rocmPackages.amdsmi}/share/amd_smi"
          "--prefix"
          "LD_LIBRARY_PATH"
          ":"
          (lib.makeLibraryPath (
            map lib.getLib [
              rocmPackages.clr
              rocmPackages.rocm-runtime
            ]
          ))
          "--set"
          "FLASH_ATTENTION_TRITON_AMD_ENABLE"
          "TRUE"
        ];

        dontCheckRuntimeDeps = true;
      });
    };
  };
  python3Packages = final.python3.pkgs;

  # Unpin vllm from python312 (matching nixpkgs PR #487987)
  vllm = with final.python3Packages; toPythonApplication vllm;
}
