# CI consumes Celler and cache.nixos.org directly; never query its own cache.
{ inputs, den, ... }:
let
  inherit (inputs) dotfiles-secrets;
  caches = import ../../_lib/ci-caches.nix inputs;
  attic = import "${dotfiles-secrets}/attic.nix";
in
{
  den.aspects.erdtree = {
    includes = [ den.aspects.celler-netrc ];
    nixos = {
      age.secrets.attic-netrc.file = "${dotfiles-secrets}/attic-netrc.age";
      nix.settings = {
        extra-substituters = [ "${caches.cellerURL}/${attic.cacheName}" ];
        extra-trusted-public-keys = [ attic.publicKey ];
      };
    };
  };
}
