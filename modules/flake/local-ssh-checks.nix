{ inputs, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks.local-ssh = import ../home/_local-ssh/checks.nix { inherit inputs pkgs lib; };
    };
}
