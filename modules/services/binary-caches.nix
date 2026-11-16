# Binary-cache client aspect. Trusts + substitutes from TWO caches — attic and
# the self-hosted garnix CI cache — so local builds skip anything either has
# already built. Keep the existing Attic URL, public key and secret names during
# the Celler migration: Nix substitution is unchanged; only the upload API moves.
{ inputs, ... }:
let
  inherit (inputs) dotfiles-secrets;
  domains = import "${dotfiles-secrets}/domains.nix";
  attic = import "${dotfiles-secrets}/attic.nix";
  garnix = import "${dotfiles-secrets}/garnix.nix";
in
{
  den.aspects.binary-caches = {
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

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ inputs.celler.packages.${pkgs.stdenv.hostPlatform.system}.celler ];
        xdg.configFile."celler/config.toml".text = ''
          default-server = "default-server"
          [servers.default-server]
          endpoint = "https://${domains.atticDomain}/"
          token-file = "/run/agenix/attic-token"
        '';
        home.shellAliases = {
          "celler-push-${attic.cacheName}" = "celler push ${attic.cacheName}";
          "celler-info-${attic.cacheName}" = "celler cache info ${attic.cacheName}";
        };
      };
  };
}
