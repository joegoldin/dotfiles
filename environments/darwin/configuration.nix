{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  username,
  hostname,
  stateVersion,
  ...
}:
import ../common/default.nix {
  inherit lib inputs outputs config pkgs username hostname stateVersion;
}
// {
  imports = [
    ./system.nix
    ./apps.nix
  ];

  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;

  services.nix-daemon.enable = true;

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
    hostPlatform = "aarch64-darwin";
  };

  users.users = {
    "${username}" = {
      shell = pkgs.bash;
      description = username;
    };
  };
}
