# Services configuration for RackNerd VPS
# Runs happy-server (handy), happy-redis, and PostgreSQL - accessible only via Tailscale
let
  domains = import ../../../secrets/domains.nix;
in
{
  config,
  lib,
  pkgs,
  username,
  ...
}: {
  # Caddy reverse proxy for HTTPS access to Happy Server
  services.caddy = {
    enable = true;
    virtualHosts."${domains.sshDomain}:3006" = {
      extraConfig = ''
        reverse_proxy localhost:3005
      '';
    };
  };
  # PostgreSQL database for happy-server
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    # Listen on all interfaces (secured by authentication rules)
    settings = {
      listen_addresses = lib.mkForce "*";
    };
    ensureDatabases = ["happy"];
    ensureUsers = [
      {
        name = "happy";
        ensureDBOwnership = true;
      }
    ];
    # Allow docker containers to connect, deny everything else
    authentication = lib.mkForce ''
      # Allow local unix socket connections
      local all all trust
      # Allow localhost connections
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
      # Allow Docker bridge connections for happy database
      host happy happy 172.17.0.0/16 trust
      # Deny all other connections
      host all all 0.0.0.0/0 reject
      host all all ::/0 reject
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
      # Disable protected mode to allow Docker container connections
      protected-mode = "no";
    };
  };

  # MinIO S3-compatible storage for happy-server
  services.minio = {
    enable = true;
    listenAddress = ":9000"; # Listen on all interfaces on port 9000
    consoleAddress = ":9001"; # Console on all interfaces on port 9001
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
    path = with pkgs; [ coreutils glibc.bin ]; # Add getent to PATH
    environment = {
      HOME = "/var/lib/minio";
      MC_CONFIG_DIR = "/var/lib/minio/.mc";
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "minio-setup" ''
        set -e

        # Wait for MinIO to be ready
        echo "Waiting for MinIO to be ready..."
        for i in {1..30}; do
          if ${pkgs.curl}/bin/curl -f http://127.0.0.1:9000/minio/health/live 2>/dev/null; then
            break
          fi
          echo "Attempt $i/30: MinIO not ready yet..."
          sleep 2
        done

        # Create .mc directory
        mkdir -p /var/lib/minio/.mc

        # Create bucket if it doesn't exist
        echo "Setting up MinIO alias..."
        ${pkgs.minio-client}/bin/mc alias set local http://127.0.0.1:9000 minioadmin minioadmin

        echo "Creating bucket..."
        ${pkgs.minio-client}/bin/mc mb local/happy --ignore-existing || true

        echo "Setting bucket policy..."
        ${pkgs.minio-client}/bin/mc anonymous set download local/happy || true

        echo "MinIO setup complete!"
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
          "0.0.0.0:3000:3000" # Bind to all interfaces (protected by firewall, accessible via Tailscale)
          "0.0.0.0:3005:3005" # Bind to all interfaces (protected by firewall, accessible via Tailscale)
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
