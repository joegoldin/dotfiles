# Attic binary-cache client; the cross-class aspect: one feature, three
# Nix classes. `os` forwards into both nixos and darwin (substituter trust);
# homeManager carries the attic-client CLI config (and its hm module, so no
# host has to wire it separately).
{ inputs, ... }:
let
  dotfiles-secrets = inputs.dotfiles-secrets;
  domains = import "${dotfiles-secrets}/domains.nix";
  attic = import "${dotfiles-secrets}/attic.nix";
  garnix = import "${dotfiles-secrets}/garnix.nix";
in
{
  den.aspects.attic = {
    os =
      { config, lib, ... }:
      let
        hasNetrc = config.age.secrets ? attic-netrc;
      in
      {
        nix.settings = {
          # Two binary caches: attic + the self-hosted garnix CI cache, so
          # local builds skip anything either has already built. The combined
          # attic-netrc carries a `machine` entry for each (nix takes one
          # netrc-file), so no separate netrc is needed for garnix.
          extra-substituters = [
            "https://${domains.atticDomain}/${attic.cacheName}"
            "https://${domains.garnixCacheDomain}"
          ];
          extra-trusted-public-keys = [
            attic.publicKey
            garnix.cachePublicKey
          ];
          netrc-file = lib.mkIf hasNetrc config.age.secrets.attic-netrc.path;
        };
      };

    homeManager = {
      imports = [ inputs.nix-attic-infra.homeManagerModules.attic-client ];
      programs.attic-client = {
        enable = true;
        defaultServer = "default-server";
        servers.default-server = {
          endpoint = "https://${domains.atticDomain}/";
          tokenPath = "/run/agenix/attic-token";
          aliases = [ attic.cacheName ];
        };
      };
    };
  };
}
