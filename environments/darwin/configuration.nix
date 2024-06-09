{ inputs, outputs, lib, config, pkgs, username, hostname, ... }:

import ../common/default.nix {
  inherit lib inputs outputs config pkgs username hostname stateVersion;
} // {
  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;

  services.nix-daemon.enable = true;

  imports = [
    ./system.nix
    ./apps.nix
  ];

  users.users = {
    "${username}" = {
      shell = pkgs.bash;
      description = username;
    };
  };
}
