{ config, lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      checks = lib.optionalAttrs (system == "x86_64-linux") (
        let
          packages = config.flake.nixosConfigurations.elphael.config.home-manager.users.joe.home.packages;
          vllm = builtins.head (builtins.filter (package: (package.pname or "") == "vllm") packages);
          torch = builtins.head (
            builtins.filter (package: (package.pname or "") == "torch") vllm.dependencies
          );
        in
        {
          # Check the installed application, not an independently constructed scope.
          vllm-gpu-targets =
            assert vllm.env.PYTORCH_ROCM_ARCH == "gfx1100;gfx1201";
            assert lib.hasInfix ''export PYTORCH_ROCM_ARCH="gfx1100;gfx1201"'' torch.preConfigure;
            pkgs.runCommand "vllm-gpu-target-tests" { } ''
              touch "$out"
            '';
        }
      );
    };
}
