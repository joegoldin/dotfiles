# Both AMD GPU hosts use the same isolated ROCm scope, not a host-wide
# rocmSupport policy that rebuilds unrelated unstable packages.
_: {
  den.aspects.vllm = {
    nixos = { lib, ... }: {
      options.programs.vllm-rocm.enable = lib.mkEnableOption "the shared vLLM ROCm application";
      # Temporarily disabled to skip the PyTorch/AOTriton build. Enable this
      # on a host to restore both its application and the installed-app check.
      config.programs.vllm-rocm.enable = lib.mkDefault false;
    };

    homeManager =
      {
        pkgs,
        lib,
        osConfig,
        ...
      }:
      {
        home.packages = lib.optionals osConfig.programs.vllm-rocm.enable [
          (import ./_vllm/packages.nix { inherit pkgs lib; }).vllm
        ];
      };
  };
}
