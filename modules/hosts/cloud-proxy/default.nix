# cloud-proxy VPS (caddy reverse proxy + fail2ban in front of tailnet
# services). The fully-migrated exemplar host: no hosts/ tree, no
# specialArgs bridge; flake output name unchanged
# (nixosConfigurations.cloud-proxy).
#
# System config below is verbatim from the old hosts/cloud-proxy/
# {configuration,cloud-proxy}.nix; the caddy/fail2ban half of the aspect
# lives in ./services.nix (same aspect, merged by name). The user's OS
# account comes from den.aspects.joe (provides.to-hosts).
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
  keys = import "${inputs.dotfiles-secrets}/keys.nix";
in
{
  den.hosts.x86_64-linux.cloud-proxy.users.${meta.username} = { };

  den.aspects.cloud-proxy = {
    includes = [
      den.batteries.hostname
      den.aspects.nix-settings
      den.aspects.hm-settings
    ];

    nixos =
      { lib, pkgs, ... }:
      {
        imports = [
          inputs.disko.nixosModules.disko
          inputs.nix-index-database.nixosModules.default
          ./_disk-config.nix
          ./_hardware-configuration.nix
        ];

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

        # BIOS boot — disko owns /dev/sda, GRUB embedded in EF02 partition
        boot.loader.grub = {
          enable = lib.mkForce true;
          devices = lib.mkForce [ "/dev/sda" ];
        };

        users.users.root.openssh.authorizedKeys.keys = [
          keys.${meta.username}
        ];

        time.timeZone = "America/Los_Angeles";

        security.sudo.wheelNeedsPassword = false;

        programs = {
          ssh.startAgent = true;
          zsh.enable = true;
          fish.enable = true;
          nh = {
            enable = true;
            flake = "/home/${meta.username}/dotfiles";
          };
        };

        environment.systemPackages = with pkgs; [
          git
          wget
        ];

        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
          };
        };

        services.tailscale = {
          enable = true;
          useRoutingFeatures = "client";
        };

        # Tailscale MagicDNS (*.ts.net) requires systemd-resolved so tailscaled
        # can inject 100.100.100.100 as the resolver for the ts.net domain.
        services.resolved.enable = true;

        networking.firewall = {
          enable = true;
          allowedTCPPorts = [
            22
            80
            443
          ];
          trustedInterfaces = [
            "tailscale0"
          ];
        };

        system.stateVersion = lib.mkForce "25.11";
      };

    # Server CLI kit for whoever logs in here
    # (was hosts/cloud-proxy/home-manager.nix's package list).
    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          coreutils
          direnv
          file
          fish
          fzf
          gawk
          git
          gnumake
          gnupg
          gnused
          gnutar
          grc
          httpie
          jq
          nix-output-monitor
          nixfmt
          ripgrep
          tmux
          tree
          unstable.just
          unzip
          watch
          wget
          which
          yq-go
          zip
          zstd
        ];
      };
  };
}
