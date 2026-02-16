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
  agenix,
  ...
}: let
  litra-rules = pkgs.writeTextFile {
    name = "99-litra.rules";
    text = ''
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c900", GROUP="video", MODE="0660"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c901", GROUP="video", MODE="0660"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="b901", GROUP="video", MODE="0660"
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c903", GROUP="video", MODE="0660"
    '';
    destination = "/etc/udev/rules.d/99-litra.rules";
  };
in {
  system.stateVersion = "${stateVersion}";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # TODO: Re-enable lanzaboote for secure boot once system is bootstrapped
  # boot.loader.systemd-boot.enable = lib.mkForce false;
  # boot.lanzaboote = {
  #   enable = true;
  #   pkiBundle = "/var/lib/sbctl";
  # };
  boot.loader.systemd-boot.enable = true;

  boot.loader.efi.canTouchEfiVariables = true;

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
      outputs.overlays.llm-agents-packages
    ];
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
      experimental-features = "nix-command flakes";
    };
  };

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      nix-path = config.nix.nixPath;
      trusted-users = ["${username}"];
      auto-optimise-store = false;
      extra-substituters = ["https://nixpkgs-python.cachix.org"];
      extra-trusted-public-keys = ["nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU=" "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="];
    };

    gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 7d";
    };

    extraOptions = lib.optionalString (config.nix.package == pkgs.nixVersions.stable) "experimental-features = nix-command flakes";

    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

    # Disable channels entirely - use flakes only
    channel.enable = false;
  };

  networking.hostName = hostname;

  users.users = {
    "${username}" = {
      uid = 1000;
      shell = pkgs.fish;
      # You can set an initial password for your user.
      # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
      # Be sure to change it (using passwd) after rebooting!
      # hashedPassword = "";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP0vgzxNgZd51jZ3K/s64jltFRSyVLxjLPWM4Q6747Zw"
      ];
      extraGroups = ["wheel" "audio" "video" "docker" "networkmanager"];
    };
  };

  programs.zsh = {
    enable = true;
  };

  programs.fish = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    git
    unstable.sbctl
    wget
  ];

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
  services.udev.packages = [litra-rules];
}
