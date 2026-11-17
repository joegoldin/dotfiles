_: {
  perSystem = { pkgs, ... }: {
    checks.haddock =
      assert import ./_overlays/haddock-tests.nix { inherit pkgs; };
      pkgs.runCommand "haddock-tests" { } ''
        touch "$out"
      '';
  };
}
