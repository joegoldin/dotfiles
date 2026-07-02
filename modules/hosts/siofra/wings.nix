# Pelican Wings node — registers to the shared panel at pelicanDomain
# (pelican.turnin.quest, currently on bastion; migrates to erdtree later). The
# panel manages this node remotely; Wings runs the game-server containers here.
#
# The Wings API needs HTTPS for the panel's web console, so Caddy + Let's Encrypt
# fronts it on this node's direct FQDN (siofra.turnin.quest → :443 → Wings :8080).
# The node can't sit behind Cloudflare: SFTP (:2022) and game traffic can't ride
# CF's free proxy, and Pelican ties SFTP to the node FQDN.
#
# After deploy: create the node in the panel (FQDN siofra.turnin.quest, SSL on,
# Daemon Port 443, Behind Proxy on, SFTP 2022), then put its token-id/token into
# agenix and set `uuid` below.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  dotfiles-secrets = inputs.dotfiles-secrets;
in
{
  den.aspects.siofra.nixos =
    { config, ... }:
    let
      domains = import "${dotfiles-secrets}/domains.nix";
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
        # TODO(deploy): node UUID generated when this node is created in the panel.
        uuid = "REPLACE-WITH-SIOFRA-WINGS-NODE-UUID";
        remote = "https://${domains.pelicanDomain}"; # the shared panel
        tokenIdFile = config.age.secrets.siofra-pelican-token-id.path;
        tokenFile = config.age.secrets.siofra-pelican-token.path;
        extraConfig.allowed_mounts = [ "/home/${meta.username}/pelican-mounts" ];
        system.sftp = {
          host = "0.0.0.0";
          port = 2022;
        };
      };

      # Docker is required for Wings
      virtualisation.docker.enable = true;

      # TLS front for the Wings API: Caddy (Let's Encrypt) on the node's direct
      # FQDN, reverse-proxied to Wings on loopback. In the panel the node is set
      # "Behind Proxy" + SSL, Daemon Port 443; Wings stays plain-HTTP on :8080.
      services.caddy.enable = true;
      services.caddy.virtualHosts."${domains.siofraSshDomain}" = {
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
        siofra-pelican-token-id = {
          file = "${dotfiles-secrets}/siofra-pelican-token-id.age";
          mode = "0644";
        };
        siofra-pelican-token = {
          file = "${dotfiles-secrets}/siofra-pelican-token.age";
          mode = "0644";
        };
      };
    };
}
