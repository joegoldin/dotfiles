{
  config,
  lib,
  dotfiles-secrets,
  ...
}:
let
  domains = import "${dotfiles-secrets}/domains.nix";
  attic = import "${dotfiles-secrets}/attic.nix";
  hasNetrc = config.age.secrets ? attic-netrc;
in
{
  nix.settings = {
    extra-substituters = [ "https://${domains.atticDomain}/${attic.cacheName}" ];
    extra-trusted-public-keys = [ attic.publicKey ];
    netrc-file = lib.mkIf hasNetrc config.age.secrets.attic-netrc.path;
  };
}
