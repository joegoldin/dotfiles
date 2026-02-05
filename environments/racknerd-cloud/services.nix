# Services configuration for RackNerd VPS
# Runs happy-server (handy), happy-redis, and PostgreSQL - accessible only via Tailscale
{
  config,
  lib,
  pkgs,
  username,
  ...
}: {
  # PostgreSQL database for happy-server
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    # Listen on localhost and docker bridge for container access
    settings = {
      listen_addresses = lib.mkForce "127.0.0.1,172.17.0.1";
    };
    ensureDatabases = ["happy"];
    ensureUsers = [
      {
        name = "happy";
        ensureDBOwnership = true;
      }
    ];
    # Allow docker containers to connect
    authentication = lib.mkAfter ''
      host happy happy 172.17.0.0/16 trust
    '';
  };

  # Redis service for happy-server
  services.redis.servers.happy = {
    enable = true;
    port = 6379;
    # Bind to localhost and docker bridge for container access
    bind = "127.0.0.1 172.17.0.1";
    # Redis configuration
    settings = {
      dir = "/var/lib/redis-happy";
      appendonly = true;
      appendfsync = "everysec";
      save = [
        "900 1"
        "300 10"
        "60 10000"
      ];
      maxmemory-policy = "noeviction";
    };
  };

  # Happy server as Docker container
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      happy-server = {
        image = "docker.korshakov.com/handy-server:latest";
        ports = [
          "127.0.0.1:3005:3005" # Bind to localhost (accessible via Tailscale)
        ];
        environment = {
          NODE_ENV = "production";
          PORT = "3005";
          # Access host services via docker bridge gateway (172.17.0.1)
          DATABASE_URL = "postgresql://happy@172.17.0.1:5432/happy";
          REDIS_URL = "redis://172.17.0.1:6379";
        };
        environmentFiles = [
          config.age.secrets.happy-secrets.path
        ];
        # Use default bridge network (no host network needed)
      };
    };
  };

  # Ensure services start in correct order
  systemd.services.docker-happy-server = {
    after = ["postgresql.service" "redis-happy.service"];
    requires = ["postgresql.service" "redis-happy.service"];
  };

  # Ensure redis data directory exists with correct permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/redis-happy 0750 redis redis -"
  ];
}
