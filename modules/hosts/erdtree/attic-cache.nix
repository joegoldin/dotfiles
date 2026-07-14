# erdtree now BUILDS (garnix CI runs builds locally), so it should pull from the
# attic binary cache to avoid rebuilding derivations that are already cached.
# (default.nix's original rationale — "the server never builds, so attic is
# omitted" — no longer holds now that garnix builds here.) This adds only the
# os-level substituter + netrc, not the home-manager attic-client CLI, since
# erdtree is a lean server that only needs to consume the cache.
{ inputs, ... }:
let
  dotfiles-secrets = inputs.dotfiles-secrets;
  domains = import "${dotfiles-secrets}/domains.nix";
  attic = import "${dotfiles-secrets}/attic.nix";
in
{
  den.aspects.erdtree.nixos =
    { config, ... }:
    {
      # attic-netrc is encrypted to all_keys (erdtree included), so it decrypts here.
      age.secrets.attic-netrc.file = "${dotfiles-secrets}/attic-netrc.age";
      nix.settings = {
        extra-substituters = [ "https://${domains.atticDomain}/${attic.cacheName}" ];
        extra-trusted-public-keys = [ attic.publicKey ];
        # Auth for the attic cache. garnix's per-build private-cache netrc is
        # layered separately (userNixConfig), so this system netrc-file doesn't
        # collide with it.
        netrc-file = config.age.secrets.attic-netrc.path;
      };
    };
}
