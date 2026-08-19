# ncro (github:manic-systems/ncro): a per-machine cache router.
#
# nix asks every substituter about every path and waits out the slow ones in
# order, which is why a switch can sit for minutes with nothing building: the
# time goes into cache round trips, not evaluation and not compilation. ncro
# measures upstream latency and answers from whichever cache is actually
# fastest, so nix makes one local request instead of several remote ones.
#
# It streams NARs straight through rather than storing them, so this adds a
# routing decision and no second copy of the cache. Only the decisions are
# persisted, in SQLite.
#
# One instance per machine, on loopback, rather than one shared instance behind
# a hostname. That is not a smaller version of the shared design, it is a
# different one, and it is better on three counts:
#
#   - Nothing is exposed. ncro re-authenticates to attic with this machine's
#     netrc and returns whatever it gets, so a shared instance reachable
#     without auth would turn attic's 401 into a 200 for whoever asked.
#     Measured: attic answers 401 without credentials, garnix and numtide
#     answer 200. A loopback instance has no such surface and needs no auth
#     layer, no DNS record and no certificate.
#   - The credential stays where it already was. Every host that should read
#     attic already decrypts attic-netrc; none has to trust another host to
#     hold it on its behalf.
#   - Latency is measured from the machine that will use the answer. The
#     fastest cache from a workstation on the LAN is not the fastest from a
#     laptop on someone else's wifi, and a shared router would average the
#     two into a decision that suits neither.
{ inputs, ... }:
let
  dotfiles-secrets = inputs.dotfiles-secrets;
  domains = import "${dotfiles-secrets}/domains.nix";
  attic = import "${dotfiles-secrets}/attic.nix";
  garnix = import "${dotfiles-secrets}/garnix.nix";

  # Loopback, and the firewall is never opened for it. ncro answers for attic
  # using this machine's netrc, so anything that can reach it can read a
  # private cache; keeping it on 127.0.0.1 means nothing can.
  listenAddress = "127.0.0.1:8899";
in
{
  den.aspects.ncro.nixos =
    {
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.ncro.nixosModules.ncro ];

      services.ncro = {
        enable = true;

        # The same netrc attic-cache.nix already decrypts. ncro is the one
        # making the upstream request now, so it needs the credential that
        # nix used to carry.
        netrcFile = config.age.secrets.attic-netrc.path;

        settings = {
          server = {
            listen = listenAddress;
            read_timeout = "30s";
            write_timeout = "30s";
            # Advertised to nix as this cache's priority. Below both upstreams
            # so nix prefers the proxy, which is the whole point.
            cache_priority = 30;
            want_mass_query = true;
          };

          # Ordered nearest-first. garnix leads because it is this machine's
          # own CI cache and a hit there is both likeliest and cheapest, attic
          # follows as the estate-wide store, cache.nixos.org is upstream, and
          # numtide is last because it holds one project's outputs
          # (llm-agents) rather than anything general.
          #
          # ncro still measures latency and can prefer a faster upstream; these
          # are the tiebreak, not a strict order.
          upstreams = [
            {
              url = "https://${domains.garnixCacheDomain}";
              priority = 0;
              public_key = garnix.cachePublicKey;
            }
            {
              url = "https://${domains.atticDomain}/${attic.cacheName}";
              priority = 10;
              public_key = attic.publicKey;
            }
            {
              url = "https://cache.nixos.org";
              priority = 20;
              public_key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
            }
            {
              url = "https://cache.numtide.com";
              priority = 30;
              public_key = "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=";
            }
          ];
        };
      };

      # One substituter instead of several, which is the change that matters:
      # nix stops fanning a query out to every cache and waiting on the
      # slowest. mkForce because the binary-caches aspect and attic-cache.nix
      # both contribute entries, and leaving them would put nix back to
      # querying the same remotes ncro is there to front.
      #
      # Trusted keys are not forced: services.ncro.addUpstreamPublicKeys adds
      # each upstream's key, and a key that is trusted but unused costs
      # nothing, where a missing one fails the substitution.
      nix.settings.substituters = lib.mkForce [ "http://${listenAddress}" ];
    };
}
