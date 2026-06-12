{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      formatter = inputs.nixpkgs-unstable.legacyPackages.${system}.nixfmt-tree;
    };
}
