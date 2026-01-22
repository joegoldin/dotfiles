# Pelican Panel and Wings configuration
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Fix missing group for redis
  users.groups.redis-pelican-panel = {};

  # PANEL - Game server management web interface
  services.pelican.panel = {
    enable = true;
    app = {
      url = "https://REDACTED_DOMAIN";
      # Generate with: echo "base64:$(openssl rand -base64 32)"
      keyFile = config.age.secrets.pelican-app-key.path;
    };
    database.passwordFile = config.age.secrets.pelican-db-password.path;
    redis.passwordFile = config.age.secrets.pelican-redis-password.path;
  };

  # WINGS - Game server daemon (runs containers)
  services.pelican.wings = {
    enable = true;
    openFirewall = true;
    uuid = "your-node-uuid"; # TODO: Get this from the panel after creating a node
    remote = "https://REDACTED_DOMAIN";
    tokenIdFile = config.age.secrets.pelican-token-id.path;
    tokenFile = config.age.secrets.pelican-token.path;
  };

  # Docker is required for Wings
  virtualisation.docker.enable = true;

  # Secrets for Pelican (create these with agenix)
  # Generate secrets:
  #   App key: echo "base64:$(openssl rand -base64 32)" > /tmp/pelican-app-key && agenix -e secrets/pelican-app-key.age
  #   DB password: openssl rand -base64 32 > /tmp/pelican-db-password && agenix -e secrets/pelican-db-password.age
  #   Redis password: openssl rand -base64 32 > /tmp/pelican-redis-password && agenix -e secrets/pelican-redis-password.age
  #   Token ID & Token: Get these from the panel after creating a node
  age.secrets = {
    pelican-app-key = {
      file = ../../secrets/pelican-app-key.age;
      mode = "400";
    };
    pelican-db-password = {
      file = ../../secrets/pelican-db-password.age;
      mode = "400";
    };
    pelican-redis-password = {
      file = ../../secrets/pelican-redis-password.age;
      mode = "400";
    };
    pelican-token-id = {
      file = ../../secrets/pelican-token-id.age;
      mode = "400";
    };
    pelican-token = {
      file = ../../secrets/pelican-token.age;
      mode = "400";
    };
  };
}
