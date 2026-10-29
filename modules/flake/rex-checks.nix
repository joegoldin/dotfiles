{ inputs, lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      checks = lib.optionalAttrs (builtins.hasAttr system inputs.rex.packages) {
        rex-config = pkgs.runCommand "rex-config-tests" { nativeBuildInputs = [ pkgs.python3 ]; } ''
          export PYTHONDONTWRITEBYTECODE=1
          python3 -m unittest discover -s ${../home/_rex} -p 'test_*.py'
          ${inputs.rex.packages.${system}.rex}/bin/rex config check ${../home/_rex/ghostty.lua}
          touch "$out"
        '';
      };
    };
}
