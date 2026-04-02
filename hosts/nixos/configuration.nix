# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
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
let
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
  streamcontroller-rules = pkgs.writeTextFile {
    name = "99-streamcontroller-osplugin.rules";
    text = ''
      KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess", GROUP="input", MODE="0660"
    '';
    destination = "/etc/udev/rules.d/99-streamcontroller-osplugin.rules";
  };
  # Priority 59 to run before systemd's default rules (systemd/systemd#39056)
  vial-rules = pkgs.writeTextFile {
    name = "59-vial.rules";
    text = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '';
    destination = "/etc/udev/rules.d/59-vial.rules";
  };
in
{
  system.stateVersion = "${stateVersion}";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

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

  # Enable aarch64 cross-compilation via QEMU
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

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

      # Disable channels entirely - use flakes only
      channel.enable = false;
    };

  time.timeZone = "America/Los_Angeles";

  networking.networkmanager.enable = true;
  networking.hostName = hostname;
  networking.firewall = {
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];
  };

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
        keys.${username}
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
      # Certain features, including CLI integration and system authentication support,
      # require enabling PolKit integration on some desktop environments (e.g. Plasma).
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

  services.locate = {
    enable = true;
  };

  services.tailscale = {
    enable = true;
    package = pkgs.unstable.tailscale;
  };

  services.udev.packages = [
    litra-rules
    streamcontroller-rules
    (import ../common/system/streamcontroller.nix { inherit pkgs; }).package
    vial-rules
  ];

  # Fix Gigabyte motherboard immediate wake from suspend
  # Disable wakeup on: PCIe ports, Intel I226-V NIC, ASMedia USB 3.1 controller
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x125c", ATTR{power/wakeup}="disabled"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1b21", ATTR{device}=="0x2142", ATTR{power/wakeup}="disabled"
  '';
}
