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
