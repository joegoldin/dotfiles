{ lib, ... }:
{
  perSystem =
    {
      pkgs,
      customPackages,
      ...
    }:
    let
      localPackages = import ./_pkgs pkgs;
      exported = ((import ./packages.nix { }).perSystem { inherit pkgs lib; }).packages;
    in
    {
      checks.package-exports =
        assert lib.isFunction customPackages.mkWindowsApp;
        assert !(exported ? mkWindowsApp);
        assert lib.all lib.isDerivation (builtins.attrValues exported);
        assert lib.all (name: !lib.isDerivation localPackages.${name} || exported ? ${name}) (
          builtins.attrNames localPackages
        );
        # Several Linux-only packages deliberately cannot produce Darwin drvPaths.
        assert
          !pkgs.stdenv.hostPlatform.isLinux
          || lib.all (name: exported.${name}.drvPath == localPackages.${name}.drvPath) (
            builtins.attrNames exported
          );
        pkgs.runCommand "package-export-tests" { } ''
          touch "$out"
        '';
    };
}
