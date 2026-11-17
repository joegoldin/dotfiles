# Repo packages remain available as flake outputs without a nixpkgs overlay.
_: {
  perSystem = { pkgs, lib, ... }: {
    # Constructors remain in customPackages; flake package outputs must be derivations.
    packages = lib.filterAttrs (_: package: lib.isDerivation package) (import ./_pkgs pkgs);
  };
}
