# Pelican Wings node — registers to the shared panel at pelicanDomain
# (pelican.turnin.quest, currently on bastion; migrates to erdtree later). The
# panel manages this node remotely; Wings runs the game-server containers here.
#
# The Wings API needs HTTPS for the panel's web console, so Caddy + Let's Encrypt
# fronts it on a dedicated subdomain (wings.erdtree.turnin.quest → :443 → Wings
# :8080), off the base domain so erdtree.turnin.quest's :443 stays free. The node
# can't sit behind Cloudflare: SFTP (:2022) and game traffic can't ride CF's free
# proxy, and Pelican ties SFTP to the node FQDN.
#
# After deploy: create the node in the panel (FQDN wings.erdtree.turnin.quest, SSL
# on, Daemon Port 443, Behind Proxy on, SFTP 2022), then put its token-id/token
# into agenix and set `uuid` below.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  dotfiles-secrets = inputs.dotfiles-secrets;
in
{
  den.aspects.erdtree.nixos =
    { config, ... }:
    let
      domains = import "${dotfiles-secrets}/domains.nix";
      pelicanNodes = import "${dotfiles-secrets}/pelican-nodes.nix";
    in
    {
      # Wings waits for agenix (its node token)
      systemd.services.pelican-wings-setup = {
        after = [ "agenix.service" ];
        wants = [ "agenix.service" ];
      };

      # WINGS - Game server daemon (runs containers), managed by the shared panel
      services.pelican.wings = {
        enable = true;
        openFirewall = false; # ports declared explicitly in the firewall block
        uuid = pelicanNodes.erdtree; # from dotfiles-secrets/pelican-nodes.nix
        remote = "https://${domains.pelicanDomain}"; # the shared panel
        tokenIdFile = config.age.secrets.erdtree-pelican-token-id.path;
        tokenFile = config.age.secrets.erdtree-pelican-token.path;
        extraConfig.allowed_mounts = [ "/home/${meta.username}/pelican-mounts" ];
        system.sftp = {
          host = "0.0.0.0";
          port = 2022;
        };
      };

      # Docker is required for Wings
      virtualisation.docker.enable = true;

      # TLS front for the Wings API: Caddy (Let's Encrypt) on a dedicated
      # subdomain (wings.erdtree.turnin.quest, direct A → this node), reverse-
      # proxied to Wings on loopback — off the base domain so its :443 is free.
      # Panel node: FQDN wings.erdtree.turnin.quest, SSL on, Daemon Port 443,
      # Behind Proxy on; Wings stays plain-HTTP on :8080.
      services.caddy.enable = true;
      services.caddy.virtualHosts."${domains.erdtreeWingsDomain}" = {
        extraConfig = ''
          reverse_proxy localhost:8080
        '';
      };

      # No provider-side ACL — this firewall is the only gate on inbound traffic.
      networking.firewall = {
        enable = true;
        # tailnet trusted for admin/SSH; docker bridge for Wings containers.
        trustedInterfaces = [
          "tailscale0"
          "docker0"
        ];
        allowedTCPPorts = [
          22 # SSH
          80 # Let's Encrypt ACME HTTP-01 + redirect to 443
          443 # Wings API (Caddy → localhost:8080)
          2022 # Wings SFTP (direct; can't ride Cloudflare)
        ];
        # Game servers (same range on every host)
        allowedTCPPortRanges = [
          {
            from = 42420;
            to = 42469;
          }
        ];
        allowedUDPPortRanges = [
          {
            from = 42420;
            to = 42469;
          }
        ];
      };

      # Ensure wings directories exist
      system.activationScripts.pelicanDirs = ''
        mkdir -p /home/${meta.username}/pelican-mounts
        chown ${meta.username}:users /home/${meta.username}/pelican-mounts
        mkdir -p /etc/pelican
        chown pelican-wings:pelican-wings /etc/pelican
      '';

      # Per-node registration token (from the panel after creating the node)
      age.secrets = {
        erdtree-pelican-token-id = {
          file = "${dotfiles-secrets}/erdtree-pelican-token-id.age";
          mode = "0644";
        };
        erdtree-pelican-token = {
          file = "${dotfiles-secrets}/erdtree-pelican-token.age";
          mode = "0644";
        };
      };
    };
}
