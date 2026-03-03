{ dotfiles-secrets, ... }:
let
  domains = import "${dotfiles-secrets}/domains.nix";
  attic = import "${dotfiles-secrets}/attic.nix";
in
{
  nix.settings = {
    extra-substituters = [ "https://${domains.atticDomain}/${attic.cacheName}" ];
    extra-trusted-public-keys = [ attic.publicKey ];
  };
}
