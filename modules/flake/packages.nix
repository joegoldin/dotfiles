# Repo packages remain available as flake outputs without a nixpkgs overlay.
_: {
  perSystem = { pkgs, lib, ... }: {
    # Keep constructors and foreign-platform packages in customPackages, not build targets.
    packages = lib.filterAttrs (
      _: package: lib.isDerivation package && lib.meta.availableOn pkgs.stdenv.hostPlatform package
    ) (import ./_pkgs pkgs);
  };
}
