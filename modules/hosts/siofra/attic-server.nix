# Keep Celler's SQLite DB, B2 bucket and cache signing keys. Chunking stays
# disabled so authorized NAR downloads use signed B2 redirects.
{ inputs, ... }:
let
  inherit (inputs) dotfiles-secrets;
  caches = import ../../_lib/ci-caches.nix inputs;
in
{
  den.aspects.siofra.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      attic = import "${dotfiles-secrets}/attic.nix";
    in
    {
      imports = [ inputs.celler.nixosModules.cellerd ];

      age.secrets.atticd-env.file = "${dotfiles-secrets}/atticd.env.age";
      services.cellerd = {
        enable = true;
        environmentFile = config.age.secrets.atticd-env.path;
        settings = {
          listen = "127.0.0.1:8081";
          api-endpoint = "${caches.cellerURL}/";
          allowed-hosts = [
            caches.cellerHost
            caches.cellerAuthority
          ];
          # mode=rw deliberately refuses to create an empty cache on migration.
          database.url = "sqlite:///var/lib/atticd/server.db?mode=rw";
          jwt.rs256-public-key-file = "/run/celler-jwt-public-key/public-key.pem";
          storage = {
            type = "s3";
            inherit (attic.b2) region bucket endpoint;
          };
          compression.type = "zstd";
          garbage-collection.interval = "12 hours";
        };
      };

      environment.systemPackages = [ config.services.cellerd.package ];
      systemd.services = {
        # Preserve tokens without giving cellerd the JWT private key.
        celler-jwt-public-key = {
          description = "Derive the Celler JWT verification key from the legacy Attic secret";
          after = [ "agenix.service" ];
          before = [ "cellerd.service" ];
          requiredBy = [ "cellerd.service" ];
          restartTriggers = [ config.age.secrets.atticd-env.file ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            EnvironmentFile = config.age.secrets.atticd-env.path;
            RuntimeDirectory = "celler-jwt-public-key";
            RuntimeDirectoryMode = "0755";
            UMask = "0022";
          };
          script = ''
            set -euo pipefail
            printf '%s' "$ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64" \
              | ${pkgs.coreutils}/bin/base64 --decode \
              | ${pkgs.openssl}/bin/openssl pkey -pubout \
                > /run/celler-jwt-public-key/public-key.pem
          '';
        };

        cellerd = {
          after = [
            "agenix.service"
            "celler-jwt-public-key.service"
          ];
          requires = [ "celler-jwt-public-key.service" ];
          serviceConfig = {
            # systemd manages ownership even when the DynamicUser changes.
            StateDirectory = lib.mkForce "atticd";
            UnsetEnvironment = [ "ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64" ];
          };
        };

        celler-tailnet = caches.serve {
          inherit config;
          backend = "http://127.0.0.1:8081";
          port = caches.cellerPort;
          unit = "cellerd";
        };
      };
    };
}
