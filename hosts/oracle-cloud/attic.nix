# Attic — self-hosted Nix binary cache
#
# Generate the credentials file on the server:
#   nix run nixpkgs#openssl -- genrsa -traditional 4096 | base64 -w0
#
# Then create atticd.env with:
#   ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="<output from above>"
#
# Encrypt it with agenix:
#   agenix -e secrets/atticd.env.age
#
# After deploying, generate an admin token:
#   atticd-atticadm make-token --sub "admin" --validity "10y" \
#     --push "*" --pull "*" --delete "*" --create-cache "*" \
#     --configure-cache "*" --configure-cache-retention "*" --destroy-cache "*"
#
{
  config,
  dotfiles-secrets,
  ...
}:
let
  domains = import "${dotfiles-secrets}/domains.nix";
in
{
  services.atticd = {
    enable = true;

    environmentFile = config.age.secrets.atticd-env.path;

    settings = {
      listen = "[::]:8081";

      api-endpoint = "https://${domains.atticDomain}/";
      allowed-hosts = [ domains.atticDomain ];

      chunking = {
        nar-size-threshold = 64 * 1024; # 64 KiB
        min-size = 16 * 1024; # 16 KiB
        avg-size = 64 * 1024; # 64 KiB
        max-size = 256 * 1024; # 256 KiB
      };

      compression = {
        type = "zstd";
      };

      garbage-collection = {
        interval = "12 hours";
      };
    };
  };

  systemd.services.atticd = {
    after = [ "agenix.service" ];
    wants = [ "agenix.service" ];
  };
}
