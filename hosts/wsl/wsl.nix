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
  dotfiles-assets,
  ...
}: let
  fonts = import ../common/system/fonts {inherit pkgs lib dotfiles-assets;};
in {
  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    wslConf.interop.appendWindowsPath = true;
    wslConf.network.generateHosts = false;
    interop.register = true;
    defaultUser = "${username}";
    startMenuLaunchers = true;

    # Wrap binaries for Cursor remote development
    wrapBinSh = true;

    # Enable integration with Docker Desktop (needs to be installed)
    docker-desktop.enable = false; # false but it works!

    extraBin = with pkgs; [
      # Binaries for Docker Desktop wsl-distro-proxy
      {src = "${coreutils}/bin/mkdir";}
      {src = "${coreutils}/bin/cat";}
      {src = "${coreutils}/bin/whoami";}
      {src = "${coreutils}/bin/ls";}
      {src = "${busybox}/bin/addgroup";}
      {src = "${su}/bin/groupadd";}
      {src = "${su}/bin/usermod";}
      # Wrapped bash for Cursor remote development
      {
        name = "bash";
        src = config.wsl.binShExe;
      }
    ];
  };
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  systemd.services.docker-desktop-proxy.script = lib.mkForce ''${config.wsl.wslConf.automount.root}/wsl/docker-desktop/docker-desktop-user-distro proxy --docker-desktop-root ${config.wsl.wslConf.automount.root}/wsl/docker-desktop "C:\Program Files\Docker\Docker\resources"'';

  system.stateVersion = "${stateVersion}";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
      outputs.overlays.llm-agents-packages
      outputs.overlays.mcps-packages
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
    git
    wget
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  fonts.packages = with pkgs; [
    fonts.berkeley-mono-nerd-font
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

  # ld for wsl for vscode server
  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld;
  };
}
