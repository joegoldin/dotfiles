# Fleet cache clients. Hydra and Celler are reachable only on the tailnet.
{ inputs, den, ... }:
let
  inherit (inputs) dotfiles-secrets;
  caches = import ../_lib/ci-caches.nix inputs;
  attic = import "${dotfiles-secrets}/attic.nix";
  signing = import "${dotfiles-secrets}/garnix.nix";
in
{
  den.aspects.binary-caches = {
    includes = [ den.aspects.celler-netrc ];
    os.nix.settings = {
      extra-substituters = [
        "${caches.cellerURL}/${attic.cacheName}"
        caches.hydraURL
      ];
      extra-trusted-public-keys = [
        attic.publicKey
        signing.cachePublicKey
      ];
    };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ inputs.celler.packages.${pkgs.stdenv.hostPlatform.system}.celler ];
        xdg.configFile."celler/config.toml".text = ''
          default-server = "default-server"
          [servers.default-server]
          endpoint = "${caches.cellerURL}/"
          token-file = "/run/agenix/attic-token"
        '';
        home.shellAliases = {
          "celler-push-${attic.cacheName}" = "celler push ${attic.cacheName}";
          "celler-info-${attic.cacheName}" = "celler cache info ${attic.cacheName}";
        };
      };
  };
}
