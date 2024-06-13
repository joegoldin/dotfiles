# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
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
    # we import these in the default.nix because we share this config with wsl
  ];

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    # Opinionated: disable channels
    channel.enable = false;
  };

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Certain features, including CLI integration and system authentication support,
    # require enabling PolKit integration on some desktop environments (e.g. Plasma).
    polkitPolicyOwners = ["${username}"];
  };

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = true;
    settings = {
      # Opinionated: forbid root login through SSH.
      PermitRootLogin = "no";
      # Opinionated: use keys only.
      # Remove if you want to SSH using passwords
      PasswordAuthentication = false;
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # ld for wsl for vscode server
  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs;
  };
}
