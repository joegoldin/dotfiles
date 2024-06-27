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
}: {
  imports = [
    ./system.nix
    ./apps.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
      inputs.brew-nix.overlays.default
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

    extraOptions = lib.optionalString (config.nix.package == pkgs.nixFlakes) "experimental-features = nix-command flakes";

    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    configureBuildUsers = true;
  };

  ids.uids.nixbld = lib.mkForce 30000;

  services.nix-daemon.enable = true;

  networking.hostName = hostname;

  users.users = {
    "${username}" = {
      shell = pkgs.zsh;
      # You can set an initial password for your user.
      # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
      # Be sure to change it (using passwd) after rebooting!
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP0vgzxNgZd51jZ3K/s64jltFRSyVLxjLPWM4Q6747Zw"
      ];
      description = username;
    };
  };

  programs.bash = {
    enable = true;
    interactiveShellInit = ''
      if [[ $(ps -o comm= -p $PPID) != "fish" && -z "$BASH_EXECUTION_STRING" ]]; then
        # Determine if the current shell is a login shell
        if shopt -q login_shell; then
          LOGIN_OPTION='--login'
        else
          LOGIN_OPTION=""
        fi

        # Execute fish shell with the determined login option
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  programs.zsh = {
    enable = true;
    interactiveShellInit = ''
      if [[ $(ps -o comm= -p $PPID) != "fish" && -z "$BASH_EXECUTION_STRING" ]]; then
        # Determine if the current shell is a login shell
        if shopt -q login_shell; then
          LOGIN_OPTION='--login'
        else
          LOGIN_OPTION=""
        fi

        # Execute fish shell with the determined login option
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  programs.fish = {
    interactiveShellInit = ''
    '';
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    git
    wget
  ];
}
