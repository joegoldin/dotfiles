{ pkgs, lib }:
let
  inherit (pkgs) unstable;
  # Keep vLLM, Torch and their ROCm libraries to the RX 7900 XTX and RX 9070 XT.
  gpuTargets = [
    "gfx1100"
    "gfx1201"
  ];
in
unstable.pkgsRocm.extend (
  _final: prev: {
    # Extend the Python scope so vLLM and its dependencies share this Torch.
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (_pythonFinal: pythonPrev: {
        # Keep vLLM and Torch's own device code on the same targets as ROCm.
        vllm = (pythonPrev.vllm.override { inherit gpuTargets; }).overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./vllm-rocm-load-triton-first.patch ];
        });
        torch = pythonPrev.torch.override { inherit gpuTargets; };
      })
    ];
    rocmPackages = prev.rocmPackages.overrideScope (
      _rocmFinal: rocmPrev:
      # Override target-aware libraries rather than clr.localGpuTargets:
      # MAGMA also inherits that default but supports neither of these GPUs.
      lib.genAttrs [
        "hipblaslt"
        "hipcub"
        "hipfft"
        "hiprand"
        "hipsparse"
        "hipsparselt"
        "migraphx"
        "miopen"
        "mivisionx"
        "rccl"
        "rocalution"
        "rocblas"
        "rocfft"
        "rocprim"
        "rocprofiler"
        "rocprofiler-sdk"
        "rocrand"
        "rocshmem"
        "rocsolver"
        "rocsparse"
        "rocthrust"
        "rocwmma"
        "rpp"
      ] (name: rocmPrev.${name}.override { inherit gpuTargets; })
      // {
        aotriton = (rocmPrev.aotriton.override { inherit gpuTargets; }).overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./aotriton-triton-3.9-offsets.patch ];
        });
        # CK still requires a gfx9 target alongside the installed GPUs.
        composable_kernel_base = rocmPrev.composable_kernel_base.override {
          gpuTargets = [ "gfx90a" ] ++ gpuTargets;
        };
      }
    );
  }
)
