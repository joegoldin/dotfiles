# Repo packages remain available as flake outputs without a nixpkgs overlay.
_: {
  perSystem = { pkgs, ... }: {
    packages = import ./_pkgs pkgs;
  };
}
