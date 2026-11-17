{ config, lib, ... }:
{
  perSystem = { pkgs, system, ... }: {
    # Follow each GPU host's aspect enablement, not an independent test switch.
    checks = lib.optionalAttrs (system == "x86_64-linux") (
      lib.mapAttrs'
        (
          host: nixos:
          let
            packages = nixos.config.home-manager.users.joe.home.packages;
            vllm = builtins.head (builtins.filter (package: (package.pname or "") == "vllm") packages);
            torch = builtins.head (
              builtins.filter (package: (package.pname or "") == "torch") vllm.dependencies
            );
            name = if host == "elphael" then "vllm-gpu-targets" else "${host}-vllm-gpu-targets";
          in
          lib.nameValuePair name (
            # Check the installed application, not an independently constructed scope.
            assert vllm.env.PYTORCH_ROCM_ARCH == "gfx1100;gfx1201";
            assert lib.hasInfix ''export PYTORCH_ROCM_ARCH="gfx1100;gfx1201"'' torch.preConfigure;
            pkgs.runCommand "${host}-vllm-gpu-target-tests" { } ''
              touch "$out"
            ''
          )
        )
        (
          lib.filterAttrs (_: nixos: nixos.config.programs.vllm-rocm.enable) {
            inherit (config.flake.nixosConfigurations) elphael volcano-manor;
          }
        )
    );
  };
}
