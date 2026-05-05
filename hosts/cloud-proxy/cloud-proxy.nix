{
  lib,
  username,
  keys,
  ...
}:
{
  users.users.root.openssh.authorizedKeys.keys = [
    keys.${username}
  ];

  time.timeZone = "America/Los_Angeles";

  security.sudo.wheelNeedsPassword = false;

  programs.ssh.startAgent = true;

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  # Tailscale MagicDNS (*.ts.net) requires systemd-resolved so tailscaled can
  # inject 100.100.100.100 as the resolver for the ts.net domain.
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
}
