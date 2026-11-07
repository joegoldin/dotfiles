{ inputs, config, ... }:
let
  overlays = builtins.attrValues config.flake.overlays;
in
{
  perSystem =
    { pkgs, system, ... }:
    let
      patched = import inputs.nixpkgs { inherit system overlays; };
    in
    {
      checks.haddock =
        assert import ./_overlays/haddock-tests.nix { pkgs = patched; };
        pkgs.runCommand "haddock-tests" { } ''
          touch "$out"
        '';
    };
}
