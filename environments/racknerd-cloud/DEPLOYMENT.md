# RackNerd VPS Deployment Guide

This guide covers deploying Happy Server to your RackNerd VPS using NixOS.

## Services Overview

- **PostgreSQL**: Database server (port 5432, internal only)
- **Redis**: Cache/queue server (port 6379, internal only)
- **MinIO**: S3-compatible object storage (port 9000, internal only)
- **Happy Server**: Relay server for Claude Code mobile
  - Port 3005: Direct HTTP access (Tailscale only)
  - Port 3006: Public HTTPS via Caddy reverse proxy
- **Caddy**: Reverse proxy with automatic HTTPS/SSL certificates
  - Provides HTTPS access on port 3006
  - Handles Let's Encrypt certificate management

## Prerequisites

1. **RackNerd VPS** with NixOS installed
2. **Tailscale** configured and running
3. **agenix** installed locally (`nix-shell -p agenix`)
4. **SSH access** to the RackNerd server
5. **Domain config**: Copy `secrets/domains.nix.example` to `secrets/domains.nix` and fill in your actual domains

## Initial Setup

### 1. Get RackNerd Host SSH Key

After deploying NixOS to RackNerd, get the host's SSH key:

```bash
ssh joe@<racknerd-ip> cat /etc/ssh/ssh_host_ed25519_key.pub
```

Update `secrets/secrets.nix` with the actual key (replace the placeholder on line 8).

### 2. Create and Encrypt Secrets

Create the secrets file with a secure random seed:

```bash
# Copy the example file
cp secrets/happy-secrets.env.example secrets/happy-secrets.env

# Generate a secure random seed
echo "HANDY_MASTER_SECRET=$(openssl rand -hex 32)" > secrets/happy-secrets.env

# Encrypt the file with agenix
agenix -e secrets/happy-secrets.env.age

# Remove the unencrypted file
rm secrets/happy-secrets.env
```

### 3. Build Happy Server Docker Image

Before deploying, build the Docker image on the server:

```bash
# SSH into the server
ssh joe@<racknerd-ip>

# Clone happy-server repo
git clone https://github.com/slopus/happy.git ~/happy
cd ~/happy/packages/happy-server

# Build the Docker image
docker build -t happy-server:latest .
```

### 4. Initialize Database Schema

After building the image, initialize the PostgreSQL database schema with Prisma:

```bash
# Run Prisma migrations to create all tables
docker run --rm \
  --network host \
  -v ~/happy:/repo \
  -e DATABASE_URL="postgresql://happy@127.0.0.1:5432/happy" \
  happy-server:latest \
  sh -c "cd /repo/packages/happy-server && npx prisma migrate deploy"
```

**Note**: This only needs to be run once during initial setup. The database schema will persist across container restarts.

### 5. Deploy to RackNerd

Deploy the configuration:

```bash
just deploy-racknerd <racknerd-ip>
```

Or manually:

```bash
nixos-anywhere --flake .#racknerd-cloud-agent --build-on-remote joe@<racknerd-ip>
```

## Accessing Services

Happy Server is accessible via multiple methods:

### Public HTTPS Access (Recommended)

Caddy provides automatic HTTPS with Let's Encrypt:

- **Public HTTPS**: `https://<YOUR_DOMAIN>:3006`
  - Accessible from anywhere
  - Automatic SSL certificates
  - Reverse proxy to Happy Server on port 3005

### Tailscale Access

Direct HTTP access via Tailscale (private network):

- **Tailscale HTTP**: `http://<racknerd-tailscale-ip>:3005`
  - Only accessible within your Tailscale network
  - Lower latency for devices on Tailscale

### Configure Happy CLI

On your computer, configure the Happy CLI to use your server:

```bash
# Option 1: Public HTTPS (works everywhere)
export HAPPY_SERVER_URL="https://<YOUR_DOMAIN>:3006"

# Option 2: Tailscale (private network only)
export HAPPY_SERVER_URL="http://<racknerd-tailscale-ip>:3005"
```

Or add to your shell config (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
echo 'export HAPPY_SERVER_URL="https://<YOUR_DOMAIN>:3006"' >> ~/.bashrc
```

### Configure Happy Mobile App

On your phone:

1. Open Happy app
2. Go to Settings
3. Set "Relay Server URL" to:
   - **Public**: `https://<YOUR_DOMAIN>:3006` (works anywhere)
   - **Tailscale**: `http://<racknerd-tailscale-ip>:3005` (requires Tailscale)
4. Save

### Via SSH Port Forwarding (Optional)

If you need direct access:

```bash
# Forward happy-server
ssh -L 3005:127.0.0.1:3005 joe@<racknerd-tailscale-ip>

# Forward postgres
ssh -L 5432:127.0.0.1:5432 joe@<racknerd-tailscale-ip>

# Forward redis
ssh -L 6379:127.0.0.1:6379 joe@<racknerd-tailscale-ip>
```

## Monitoring & Management

### Check Service Status

```bash
# SSH into the server
ssh joe@<racknerd-tailscale-ip>

# Check PostgreSQL status
sudo systemctl status postgresql

# Check Redis status
sudo systemctl status redis-happy

# Check MinIO status
sudo systemctl status minio

# Check happy-server container status
sudo systemctl status docker-happy-server

# View happy-server logs
docker logs happy-server

# View PostgreSQL logs
sudo journalctl -u postgresql -f

# View Redis logs
sudo journalctl -u redis-happy -f

# View MinIO logs
sudo journalctl -u minio -f
```

### Update Happy Server Version

To update to the latest happy-server code:

```bash
# SSH into the server
ssh joe@<racknerd-tailscale-ip>

# Pull latest changes
cd ~/happy
git pull

# Rebuild the Docker image
cd packages/happy-server
docker build -t happy-server:latest .

# Apply any new database migrations
docker run --rm \
  --network host \
  -v ~/happy:/repo \
  -e DATABASE_URL="postgresql://happy@127.0.0.1:5432/happy" \
  happy-server:latest \
  sh -c "cd /repo/packages/happy-server && npx prisma migrate deploy"

# Restart the service
sudo systemctl restart docker-happy-server
```

### Update Secrets

```bash
# Edit the encrypted secret
agenix -e secrets/happy-secrets.env.age

# Redeploy
just deploy-racknerd <racknerd-ip>

# Or just restart the service on the server
ssh joe@<racknerd-tailscale-ip> 'sudo systemctl restart docker-happy-server'
```

## Firewall Configuration

The RackNerd firewall (`environments/racknerd-cloud/racknerd-cloud.nix:31-37`) is configured to:

- **Allow**: SSH (port 22) from public internet
- **Allow**: HTTP (port 80) for ACME/Let's Encrypt certificate challenges
- **Allow**: HTTPS (port 443) for general HTTPS traffic
- **Allow**: Happy Server HTTPS (port 3006) via Caddy reverse proxy
- **Allow**: All traffic on Tailscale interface (`tailscale0`)
- **Allow**: Docker bridge traffic (internal only, 172.17.0.0/16)
- **Block**: Direct access to port 3005, PostgreSQL (5432), Redis (6379), MinIO (9000)

This ensures:
- Happy Server is accessible publicly via HTTPS on port 3006 (Caddy reverse proxy)
- Happy Server also accessible via Tailscale on port 3005 (direct HTTP)
- PostgreSQL, Redis, and MinIO remain internal only
- Docker containers can communicate with host services securely
- Automatic SSL certificate management via Let's Encrypt

## Troubleshooting

### Container won't start

Check logs:
```bash
docker logs handy-server
```

Verify secrets are accessible:
```bash
sudo ls -la /run/agenix/
```

### Redis connection refused

Check if Redis is listening:
```bash
sudo ss -tlnp | grep 6379
```

Verify Redis is running:
```bash
sudo systemctl status redis-happy
```

### Cannot access services

Verify Tailscale is connected:
```bash
tailscale status
```

Check firewall rules:
```bash
sudo iptables -L -n
```

## Architecture Notes

- **PostgreSQL** runs as a native NixOS service with automatic database/user setup
  - Listens on 127.0.0.1 (localhost) and 172.17.0.1 (Docker bridge)
  - Only accepts Docker container connections from 172.17.0.0/16 subnet
- **Redis** runs as a native NixOS service for better performance and integration
  - Listens on 127.0.0.1 (localhost) and 172.17.0.1 (Docker bridge)
- **MinIO** provides S3-compatible object storage locally
  - Listens on 127.0.0.1:9000 and 172.17.0.1:9000
  - Console accessible at 127.0.0.1:9001 (via Tailscale only)
  - Automatically creates "happy" bucket with public read access
  - Uses default credentials (minioadmin/minioadmin)
- **Happy Server** runs in Docker using locally-built image
  - Uses Docker bridge network (no host network needed)
  - Connects to PostgreSQL, Redis, and MinIO via 172.17.0.1 (Docker gateway)
  - Port 3005 mapped to localhost only (127.0.0.1:3005)
- All external access requires Tailscale connection
- Secrets managed via agenix with encryption at rest
- Only requires a single secret: the SEED for token generation

## What Happy Server Does

Happy Server is a lightweight relay that:
- Forwards encrypted messages between your phone and Claude Code
- Stores encrypted blobs (it cannot decrypt them)
- Never sees your actual code or prompts
- Is only 1,293 lines of TypeScript
- Source: https://github.com/slopus/happy-server

## File Locations

- Service config: `environments/racknerd-cloud/services.nix`
- Secrets template: `secrets/happy-secrets.env.example`
- Encrypted secrets: `secrets/happy-secrets.env.age`
- Secrets mapping: `secrets/secrets.nix`
- Main config: `environments/racknerd-cloud/racknerd-cloud.nix`
- Redis data: `/var/lib/redis-happy` (on server)
- PostgreSQL data: `/var/lib/postgresql` (on server)
