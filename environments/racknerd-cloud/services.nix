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

  # MinIO S3-compatible storage for happy-server
  services.minio = {
    enable = true;
    listenAddress = "127.0.0.1:9000 172.17.0.1:9000";
    consoleAddress = "127.0.0.1:9001";
    rootCredentialsFile = pkgs.writeText "minio-credentials" ''
      MINIO_ROOT_USER=minioadmin
      MINIO_ROOT_PASSWORD=minioadmin
    '';
    dataDir = ["/var/lib/minio/data"];
  };

  # Create happy bucket in MinIO
  systemd.services.minio-setup-bucket = {
    description = "Create happy bucket in MinIO";
    after = ["minio.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "minio-setup" ''
        # Wait for MinIO to be ready
        until ${pkgs.curl}/bin/curl -f http://127.0.0.1:9000/minio/health/live 2>/dev/null; do
          sleep 1
        done

        # Create bucket if it doesn't exist
        ${pkgs.minio-client}/bin/mc alias set local http://127.0.0.1:9000 minioadmin minioadmin
        ${pkgs.minio-client}/bin/mc mb local/happy --ignore-existing
        ${pkgs.minio-client}/bin/mc anonymous set download local/happy
      '';
    };
  };

  # Happy server as Docker container
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      happy-server = {
        # We'll build this image manually on the server
        image = "happy-server:latest";
        ports = [
          "127.0.0.1:3005:3005" # Bind to localhost (accessible via Tailscale)
        ];
        environment = {
          NODE_ENV = "production";
          PORT = "3005";
          # Access host services via docker bridge gateway (172.17.0.1)
          DATABASE_URL = "postgresql://happy@172.17.0.1:5432/happy";
          REDIS_URL = "redis://172.17.0.1:6379";
          # Local MinIO S3 storage
          S3_HOST = "172.17.0.1";
          S3_PORT = "9000";
          S3_USE_SSL = "false";
          S3_ACCESS_KEY = "minioadmin";
          S3_SECRET_KEY = "minioadmin";
          S3_BUCKET = "happy";
          S3_PUBLIC_URL = "http://172.17.0.1:9000/happy";
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
    after = ["postgresql.service" "redis-happy.service" "minio.service" "minio-setup-bucket.service"];
    requires = ["postgresql.service" "redis-happy.service" "minio.service" "minio-setup-bucket.service"];
  };

  # Ensure redis data directory exists with correct permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/redis-happy 0750 redis redis -"
  ];
}
