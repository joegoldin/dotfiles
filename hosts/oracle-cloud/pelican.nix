# Pelican Panel and Wings configuration
#
# Create admin user:
#   cd /var/lib/pelican-panel
#   nix-shell -p php --run "sudo -u pelican-panel php /nix/store/*pelican-panel*/artisan p:user:make"
#
{
  config,
  dotfiles-secrets,
  ...
}:
let
  domains = import "${dotfiles-secrets}/domains.nix";
  panelCfg = config.services.pelican.panel;
in
{
  # Fix missing group for redis
  users.groups.redis-pelican-panel = { };

  # Ensure pelican services wait for agenix secrets
  systemd.services = {
    pelican-panel-setup = {
      after = [ "agenix.service" ];
      wants = [ "agenix.service" ];
      # Re-add dependencies lost by enableNginx = false
      requiredBy = [ "phpfpm-pelican-panel.service" ];
      before = [ "phpfpm-pelican-panel.service" ];
    };
    pelican-wings-setup = {
      after = [ "agenix.service" ];
      wants = [ "agenix.service" ];
    };
    phpfpm-pelican-panel = {
      requires = [ "pelican-panel-setup.service" ];
    };
  };

  # PANEL - Game server management web interface
  services.pelican.panel = {
    enable = true;
    enableNginx = false;
    group = "caddy";
    app = {
      url = "https://${domains.pelicanDomain}";
      # Generate with: echo "base64:$(openssl rand -base64 32)"
      keyFile = config.age.secrets.pelican-app-key.path;
    };
    database.passwordFile = config.age.secrets.pelican-db-password.path;
    redis.passwordFile = config.age.secrets.pelican-redis-password.path;
  };

  # PHP-FPM pool for Pelican Panel (replaces the one from enableNginx)
  services.phpfpm.pools.pelican-panel = {
    user = panelCfg.user;
    group = "caddy";
    phpPackage = panelCfg.phpPackage;
    settings = {
      "listen.owner" = "caddy";
      "listen.group" = "caddy";
      "pm" = "dynamic";
      "pm.max_children" = 5;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 3;
    };
  };

  # Caddy reverse proxy for Pelican Panel
  services.caddy.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.caddy.virtualHosts."http://${domains.pelicanDomain}" = {
    extraConfig = ''
      root * ${panelCfg.package}/public
      php_fastcgi unix/${config.services.phpfpm.pools.pelican-panel.socket}
      file_server
      encode gzip
      request_body {
        max_size 100MB
      }
    '';
  };

  # WINGS - Game server daemon (runs containers)
  services.pelican.wings = {
    enable = true;
    openFirewall = true; # Opens API (8080) and SFTP (2022) ports
    uuid = "dab990d7-ea48-498a-846c-d4afe46cee1e";
    remote = "https://${domains.pelicanDomain}";
    tokenIdFile = config.age.secrets.pelican-token-id.path;
    tokenFile = config.age.secrets.pelican-token.path;
    allowedMounts = [ "/home/joe/pelican-mounts" ];
    system.sftp = {
      host = "0.0.0.0";
      port = 2022;
    };
  };

  # Docker is required for Wings
  virtualisation.docker.enable = true;

  # Open firewall ports for Wings API, SFTP, and game servers
  networking.firewall = {
    allowedTCPPorts = [
      8080
      2022
    ];
    allowedTCPPortRanges = [
      {
        from = 25565;
        to = 25665;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 25565;
        to = 25665;
      }
    ];
  };

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
      file = "${dotfiles-secrets}/pelican-app-key.age";
      mode = "0644";
    };
    pelican-db-password = {
      file = "${dotfiles-secrets}/pelican-db-password.age";
      mode = "0644";
    };
    pelican-redis-password = {
      file = "${dotfiles-secrets}/pelican-redis-password.age";
      mode = "0644";
    };
    pelican-token-id = {
      file = "${dotfiles-secrets}/pelican-token-id.age";
      mode = "0644";
    };
    pelican-token = {
      file = "${dotfiles-secrets}/pelican-token.age";
      mode = "0644";
    };
  };
}
