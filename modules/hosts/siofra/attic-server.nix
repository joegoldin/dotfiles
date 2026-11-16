# Celler replaces Attic in place: keep the SQLite DB, B2 bucket, URL and cache
# signing keys. A database backup is mandatory before the first activation.
# Chunking stays disabled so NAR downloads redirect straight to B2.
{ inputs, ... }:
let
  inherit (inputs) dotfiles-secrets;
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
      domains = import "${dotfiles-secrets}/domains.nix";
      attic = import "${dotfiles-secrets}/attic.nix";
    in
    {
      imports = [ inputs.celler.nixosModules.cellerd ];

      # Retain the encrypted secret and derive only its public JWT key at runtime.
      # This preserves existing tokens without giving cellerd the private key.
      age.secrets.atticd-env.file = "${dotfiles-secrets}/atticd.env.age";
      systemd.services.celler-jwt-public-key = {
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

      services.cellerd = {
        enable = true;
        environmentFile = config.age.secrets.atticd-env.path;
        settings = {
          listen = "[::1]:8081";
          api-endpoint = "https://${domains.atticDomain}/";
          allowed-hosts = [ domains.atticDomain ];
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
      systemd.services.cellerd = {
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

      services.caddy = {
        enable = true;
        virtualHosts."${domains.atticDomain}".extraConfig = ''
          reverse_proxy http://[::1]:8081
        '';
      };
    };
}
