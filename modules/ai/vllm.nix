# Both AMD GPU hosts use the same isolated ROCm scope, not a host-wide
# rocmSupport policy that rebuilds unrelated unstable packages.
_: {
  den.aspects.vllm.homeManager =
    { pkgs, lib, ... }:
    {
      home.packages = [
        (import ./_vllm/packages.nix { inherit pkgs lib; }).vllm
      ];
    };
}
