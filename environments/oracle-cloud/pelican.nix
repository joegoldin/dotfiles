# Pelican Panel and Wings configuration
#
# Create admin user:
#   cd /var/lib/pelican-panel
#   nix-shell -p php --run "sudo -u pelican-panel php /nix/store/*pelican-panel*/artisan p:user:make"
#
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Fix missing group for redis
  users.groups.redis-pelican-panel = {};

  # Ensure pelican services wait for agenix secrets
  systemd.services.pelican-panel-setup.after = ["agenix.service"];
  systemd.services.pelican-panel-setup.wants = ["agenix.service"];
  systemd.services.pelican-wings-setup.after = ["agenix.service"];
  systemd.services.pelican-wings-setup.wants = ["agenix.service"];

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
    openFirewall = true; # Opens API (8080) and SFTP (2022) ports
    uuid = "dab990d7-ea48-498a-846c-d4afe46cee1e";
    remote = "https://REDACTED_DOMAIN";
    tokenIdFile = config.age.secrets.pelican-token-id.path;
    tokenFile = config.age.secrets.pelican-token.path;
    allowedMounts = ["/home/joe/pelican-mounts"];
    system.sftp = {
      host = "0.0.0.0";
      port = 2022;
    };
  };

  # Docker is required for Wings
  virtualisation.docker.enable = true;

  # Ensure pelican directories exist
  system.activationScripts.pelicanDirs = ''
    mkdir -p /home/joe/pelican-mounts
    chown joe:users /home/joe/pelican-mounts
    mkdir -p /etc/pelican
    chown pelican-wings:pelican-wings /etc/pelican
  '';

  # Secrets for Pelican (create these with agenix)
  # Generate secrets:
  #   App key: echo "base64:$(openssl rand -base64 32)" > /tmp/pelican-app-key && agenix -e secrets/pelican-app-key.age
  #   DB password: openssl rand -base64 32 > /tmp/pelican-db-password && agenix -e secrets/pelican-db-password.age
  #   Redis password: openssl rand -base64 32 > /tmp/pelican-redis-password && agenix -e secrets/pelican-redis-password.age
  #   Token ID & Token: Get these from the panel after creating a node
  age.secrets = {
    pelican-app-key = {
      file = ../../secrets/pelican-app-key.age;
      mode = "0644";
    };
    pelican-db-password = {
      file = ../../secrets/pelican-db-password.age;
      mode = "0644";
    };
    pelican-redis-password = {
      file = ../../secrets/pelican-redis-password.age;
      mode = "0644";
    };
    pelican-token-id = {
      file = ../../secrets/pelican-token-id.age;
      mode = "0644";
    };
    pelican-token = {
      file = ../../secrets/pelican-token.age;
      mode = "0644";
    };
  };
}
