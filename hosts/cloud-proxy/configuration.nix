{
  inputs,
  commonOverlays,
  lib,
  config,
  pkgs,
  username,
  hostname,
  keys,
  ...
}:
{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # BIOS boot — disko owns /dev/sda, GRUB embedded in EF02 partition
  boot.loader.grub = {
    enable = lib.mkForce true;
    devices = lib.mkForce [ "/dev/sda" ];
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

  networking.hostName = hostname;

  users.users."${username}" = {
    uid = 1000;
    shell = pkgs.fish;
    isNormalUser = true;
    openssh.authorizedKeys.keys = [ keys.${username} ];
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  programs = {
    zsh.enable = true;
    fish.enable = true;
    nh = {
      enable = true;
      flake = "/home/${username}/dotfiles";
    };
  };

  environment.systemPackages = with pkgs; [
    git
    wget
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
