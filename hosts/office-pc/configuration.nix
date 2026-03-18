# hosts/office-pc/configuration.nix
{
  inputs,
  commonOverlays,
  lib,
  config,
  pkgs,
  username,
  hostname,
  stateVersion,
  agenix,
  keys,
  ...
}:
{
  system.stateVersion = "${stateVersion}";

  # Lanzaboote replaces systemd-boot for secure boot
  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };

  nixpkgs = {
    overlays = commonOverlays;
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
      experimental-features = "nix-command flakes";
    };
  };

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        nix-path = config.nix.nixPath;
        trusted-users = [ "${username}" ];
        auto-optimise-store = false;
        builders-use-substitutes = true;
        cores = 20;
      };

      gc = {
        automatic = lib.mkDefault true;
        options = lib.mkDefault "--delete-older-than 7d";
      };

      extraOptions = lib.optionalString (
        config.nix.package == pkgs.nixVersions.stable
      ) "experimental-features = nix-command flakes";

      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

      channel.enable = false;
    };

  time.timeZone = "America/Los_Angeles";

  networking.networkmanager.enable = true;
  networking.hostName = hostname;

  users.users = {
    "${username}" = {
      uid = 1000;
      shell = pkgs.fish;
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        keys.joe
      ];
      extraGroups = [
        "wheel"
        "audio"
        "video"
        "docker"
        "networkmanager"
        "input"
      ];
    };
  };

  programs = {
    zsh.enable = true;
    fish.enable = true;
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "${username}" ];
    };
    nix-ld.enable = true;
    nh = {
      enable = true;
      flake = "/home/${username}/dotfiles";
    };
  };

  environment.systemPackages = with pkgs; [
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    git
    unstable.sbctl
    wget
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  services.tailscale.enable = true;

  # Hoopsnake initrd networking
  boot.initrd.network.hoopsnake.tailscale.name = "office-pc-boot";

  # USB ethernet NIC driver for initrd networking
  boot.initrd.availableKernelModules = [ "r8152" ];

  services.locate = {
    enable = true;
  };
}
