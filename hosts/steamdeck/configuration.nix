# hosts/steamdeck/configuration.nix
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

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  nixpkgs = {
    overlays = commonOverlays;
    config = {
      allowUnfree = true;
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
        auto-optimise-store = true;
        builders-use-substitutes = true;
      };

      gc = {
        automatic = lib.mkDefault true;
        options = lib.mkDefault "--delete-older-than 14d";
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

  users.users."${username}" = {
    uid = 1000;
    shell = pkgs.fish;
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      keys.${username}
    ];
    extraGroups = [
      "wheel"
      "audio"
      "video"
      "networkmanager"
      "input"
    ];
  };

  programs = {
    fish.enable = true;
    nix-ld.enable = true;
    nh = {
      enable = true;
      flake = "/home/${username}/dotfiles";
    };
  };

  environment.systemPackages = with pkgs; [
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    git
    wget
  ];

  # KDE Plasma desktop (for switching out of Game Mode)
  services.desktopManager.plasma6.enable = true;

  # Virtual keyboard for touchscreen use in Desktop Mode
  programs.maliit-keyboard.enable = true;

  # Strip default KDE bloat — keep it lean for a gaming device
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    discover
    elisa
    kate
    khelpcenter
    kmailtransport
    konsole
    krdp
    kwallet
    kwallet-pam
    oxygen
    plasma-welcome
    print-manager
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
  };
}
