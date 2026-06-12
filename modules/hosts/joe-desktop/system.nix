# Base system config (lanzaboote, desktop services, udev rules);
# nix/nixpkgs settings come from den.aspects.nix-settings (job caps below);
# OS account from den.aspects.joe.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.aspects.joe-desktop.nixos =
    { lib, pkgs, ... }:
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
        # Disable deep NVMe power states. The Corsair MP600 PRO LPX (Phison E18)
        # backing /mnt/data1 was hitting write I/O timeouts when waking from
        # APST low-power states, causing filesystem stalls. SMART is clean;
        # this is a known firmware/power-state interaction.
        kernelParams = [ "nvme_core.default_ps_max_latency_us=0" ];
      };

      # Enable aarch64 cross-compilation via QEMU
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

      # Desktop nix tuning (deltas from den.aspects.nix-settings)
      nix.settings = {
        builders-use-substitutes = true;
        # Default: 2 jobs × 4 threads = 8 max threads. machine.nix raises this.
        max-jobs = lib.mkDefault 2;
        cores = lib.mkDefault 4;
      };

      time.timeZone = "America/Los_Angeles";

      networking.networkmanager.enable = true;
      networking.firewall = {
        allowedTCPPorts = [ 53317 ];
        allowedUDPPorts = [ 53317 ];
      };

      users.users.${meta.username}.extraGroups = [
        "audio"
        "video"
        "docker"
        "input"
      ];

      programs = {
        zsh.enable = true;
        fish.enable = true;
        _1password.enable = true;
        _1password-gui = {
          enable = true;
          # Certain features, including CLI integration and system authentication support,
          # require enabling PolKit integration on some desktop environments (e.g. Plasma).
          polkitPolicyOwners = [ meta.username ];
        };
        nix-ld.enable = true;
        nix-index-database.comma.enable = true;
      };

      environment.systemPackages = with pkgs; [
        inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
        git
        unstable.sbctl
        wget
      ];

      services.openssh = {
        enable = true;
        settings = {
          # Opinionated: forbid root login through SSH.
          PermitRootLogin = "no";
          # Opinionated: use keys only.
          PasswordAuthentication = false;
        };
      };

      services.locate = {
        enable = true;
      };

      # Periodic TRIM for all SSDs (weekly).
      services.fstrim.enable = true;

      services.tailscale = {
        enable = true;
        package = pkgs.unstable.tailscale;
      };

      services.udev.packages = [
        litra-rules
        streamcontroller-rules
        (import ../../system/_streamcontroller.nix { inherit pkgs; }).package
        vial-rules
      ];

      # Fix Gigabyte motherboard immediate wake from suspend
      # Disable wakeup on: PCIe ports, Intel I226-V NIC, ASMedia USB 3.1 controller
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x125c", ATTR{power/wakeup}="disabled"
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1b21", ATTR{device}=="0x2142", ATTR{power/wakeup}="disabled"
      '';
    };
}
