# Attic: self-hosted Nix binary cache (migrated here from rennala).
#
# Why siofra: benchmarked closest to Backblaze B2 us-west-000 (~64 ms TTFB vs
# ~185 ms on erdtree) with unlimited bandwidth — the best home for the cache.
#
# KEY DIFFERENCE FROM THE OLD RENNALA SETUP: chunking is DISABLED
# (`nar-size-threshold = 0`). With chunking on, atticd stored each NAR as many
# 64 KiB content-defined chunks and had to reassemble + stream every download
# through the server (only 2 chunks prefetched at a time → ~1 MB/s). With
# chunking off, each newly-uploaded NAR is a single S3 object, so atticd's
# `get_nar` handler takes the `chunks.len() == 1` branch and 307-redirects the
# client straight to a presigned B2 URL (server out of the data path) — exactly
# how the garnix cache serves NARs. Trade-off: no chunk-level dedup (more B2
# storage; fine — NARs are already zstd-compressed). Existing chunked NARs keep
# streaming until they're re-pushed; only new uploads get the fast path.
#
# STATE: the narinfo/chunk metadata lives in a local SQLite DB at
# /var/lib/atticd/server.db (NAR bytes are in B2). Migrating hosts REQUIRES
# carrying that DB over, or the cache looks empty. See the cutover runbook in
# dotfiles-secrets/docs/server-hosts.md.
#
# To generate an admin token (same as before):
#   atticd-atticadm make-token --sub "admin" --validity "10y" \
#     --push "*" --pull "*" --delete "*" --create-cache "*" \
#     --configure-cache "*" --configure-cache-retention "*" --destroy-cache "*"
{ inputs, ... }:
let
  dotfiles-secrets = inputs.dotfiles-secrets;
in
{
  den.aspects.siofra.nixos =
    { config, ... }:
    let
      domains = import "${dotfiles-secrets}/domains.nix";
      attic = import "${dotfiles-secrets}/attic.nix";
    in
    {
      # atticd.env.age must be encrypted to siofra's host key (see secrets.nix).
      age.secrets.atticd-env.file = "${dotfiles-secrets}/atticd.env.age";

      services.atticd = {
        enable = true;

        environmentFile = config.age.secrets.atticd-env.path;

        settings = {
          listen = "[::]:8081";

          api-endpoint = "https://${domains.atticDomain}/";
          allowed-hosts = [ domains.atticDomain ];

          # Chunking disabled → single-object NARs → attic redirects downloads
          # to presigned B2 URLs (see the header comment). Threshold 0 turns it
          # off entirely; the min/avg/max below are inert while it's 0 but the
          # [chunking] section must still be present.
          chunking = {
            nar-size-threshold = 0;
            min-size = 16 * 1024;
            avg-size = 64 * 1024;
            max-size = 256 * 1024;
          };

          storage = {
            type = "s3";
            inherit (attic.b2) region bucket endpoint;
          };

          compression = {
            type = "zstd";
          };

          garbage-collection = {
            interval = "12 hours";
          };
        };
      };

      # Caddy already runs on this box (wings.nix); this just adds the cache
      # vhost. ACME needs port 80/443, both already open in wings.nix's firewall.
      services.caddy = {
        enable = true;
        virtualHosts."${domains.atticDomain}" = {
          extraConfig = ''
            reverse_proxy http://[::1]:8081
          '';
        };
      };

      systemd.services.atticd = {
        after = [ "agenix.service" ];
        wants = [ "agenix.service" ];
      };
    };
}
