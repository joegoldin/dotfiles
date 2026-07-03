# Machine-specific config: root ssh key, timezone, static LAN IP, tailscale,
# docker, AMD microcode/firmware.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  keys = import "${inputs.dotfiles-secrets}/keys.nix";
  username = meta.username;
in
{
  den.aspects.melina.nixos =
    { lib, ... }:
    {
      users.users.root.openssh.authorizedKeys.keys = [
        keys.${username}
      ];

      users.users.${meta.username}.extraGroups = [
        "docker"
        "wheel"
      ];

      time.timeZone = "America/Los_Angeles";

      # AMD Ryzen: CPU microcode + redistributable firmware (Radeon iGPU, etc.)
      hardware.enableRedistributableFirmware = true;
      hardware.cpu.amd.updateMicrocode = true;

      # Static LAN IP (the box was DHCP→192.168.0.236; pin it so Home Assistant
      # integrations that reference the IP keep working). Confirm the interface
      # name is enp1s0 after install (Intel I225-V) and adjust if it differs.
      networking = {
        useDHCP = lib.mkForce false;
        interfaces.enp1s0.ipv4.addresses = [
          {
            address = "192.168.0.236";
            prefixLength = 24;
          }
        ];
        defaultGateway = "192.168.0.1";
        nameservers = [
          "192.168.0.1"
          "1.1.1.1"
        ];
        # Homebridge runs its own avahi in-container for HomeKit mDNS, so keep the
        # host's avahi off (avoid a 5353 conflict). (avahi is off by default.)
      };

      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };

      programs.ssh.startAgent = true;

      virtualisation.docker.enable = true;
      users.extraGroups.docker.members = [ "${username}" ];

      # First NixOS release installed on this machine (fresh install off the
      # nixos-26.05 flake). Never change after install — see the NixOS manual.
      system.stateVersion = lib.mkForce "26.05";
    };
}
