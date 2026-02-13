# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  username,
  ...
}: {
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP0vgzxNgZd51jZ3K/s64jltFRSyVLxjLPWM4Q6747Zw"
  ];

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  services.cloudflared = {
    enable = true;
    tunnels = {
      "dd9aada3-d855-47fd-b782-f5314c2bb81e" = {
        credentialsFile = config.age.secrets.cf.path;
        default = "http_status:404";
      };
    };
  };

  programs.ssh.startAgent = true;

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "server";

  virtualisation.docker.enable = true;
  users.extraGroups.docker.members = ["${username}"];

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = lib.mkForce "24.11"; # Did you read the comment?
}
