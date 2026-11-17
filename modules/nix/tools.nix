# Carried by the user aspect, including lean hosts that skip cli-packages.
{ inputs, ... }:
{
  den.aspects.nix-tools.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.nix-fast-build
        pkgs.nix-update
        (pkgs.callPackage "${inputs.fast-nix-gc}/nix/package.nix" { })
      ];
    };
}
