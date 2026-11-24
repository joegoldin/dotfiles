{ inputs, ... }:
{
  den.aspects.owly = {
    homeManager = import ./_owly/plasma.nix;

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        owly = lib.getExe config.services.owly.package;
      in
      {
        imports = [ inputs.owly.nixosModules.default ];

        services.owly = {
          # The upstream driver table selects exclusive mode for iwlwifi.
          enable = true;
          openFirewall = false;
          package = (pkgs.callPackage "${inputs.owly}/nix/package.nix" { }).overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./_owly/confirm-with.patch ];
          });
        };

        assertions = [
          {
            assertion = config.networking.firewall.enable && config.networking.firewall.backend == "iptables";
            message = "Owly's AWDL isolation requires the iptables firewall on this host.";
          }
        ];
        # Process AWDL before the global desktop port allowances. Owly uses IPv6
        # link-local mDNS and TCP, and needs neighbor discovery on its TAP link.
        networking.firewall.extraCommands = ''
          ip46tables -I nixos-fw 1 -i awdl0 -j nixos-fw-refuse
          ip6tables -I nixos-fw 1 -i awdl0 -s fe80::/10 -m conntrack --ctstate ESTABLISHED,RELATED -j nixos-fw-accept
          ip6tables -I nixos-fw 1 -i awdl0 -p ipv6-icmp --icmpv6-type 135 -j nixos-fw-accept
          ip6tables -I nixos-fw 1 -i awdl0 -s fe80::/10 -p ipv6-icmp --icmpv6-type 136 -j nixos-fw-accept
          ip6tables -I nixos-fw 1 -i awdl0 -s fe80::/10 -p udp --dport 5353 -j nixos-fw-accept
          ip6tables -I nixos-fw 1 -i awdl0 -s fe80::/10 -d fe80::/10 -p tcp --dport 8771 -j nixos-fw-accept
          ip46tables -I FORWARD 1 -i awdl0 -j DROP
          ip46tables -I FORWARD 1 -o awdl0 -j DROP
        '';
        networking.firewall.extraStopCommands = ''
          ip46tables -D FORWARD -i awdl0 -j DROP 2>/dev/null || true
          ip46tables -D FORWARD -o awdl0 -j DROP 2>/dev/null || true
        '';
        # Owly handles AWDL mDNS itself; don't advertise LAN services on awdl0.
        services.avahi.denyInterfaces = [ "awdl0" ];

        # Keep the radio lease across logins, but leave file acceptance interactive.
        systemd.services.owly-radio = {
          description = "Hold the Owly AirDrop radio lease";
          wantedBy = [ "multi-user.target" ];
          after = [
            "firewall.service"
            "NetworkManager.service"
            "owlyd.service"
          ];
          requires = [
            "firewall.service"
            "NetworkManager.service"
            "owlyd.service"
          ];
          partOf = [ "owlyd.service" ];
          serviceConfig = {
            ExecStart = "${owly} radio up";
            Restart = "on-failure";
            RestartSec = "10s";
            NoNewPrivileges = true;
            CapabilityBoundingSet = "";
          };
        };

        environment.systemPackages = [
          (pkgs.writeShellScriptBin "owly-receive" ''
            exec ${owly} receive --dir "$HOME/Downloads" "$@"
          '')
        ];
      };
  };
}
