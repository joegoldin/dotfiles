# hosts/nixos/system/joe-desktop.nix
# Specific configuration for joe-desktop tower machine
{
  pkgs,
  lib,
  username,
  dotfiles-assets,
  ...
}:
let
  fonts = import ../common/system/fonts { inherit pkgs lib dotfiles-assets; };
in
{
  # Cap nix builds: 3 parallel jobs × 6 threads each = 18 max threads. Memory
  # is throttled at 32 GiB (MemoryHigh, soft) with a 42 GiB hard ceiling
  # (MemoryMax) on the nix-daemon cgroup — High slows builds down via reclaim
  # pressure rather than OOM-killing them, while Max keeps a single runaway
  # link step from taking down the whole 64 GiB box.
  nix.settings.max-jobs = 3;
  nix.settings.cores = 6;

  # TODO: Add litra-autotoggle as a service to systemd

  # ssh with 1password
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    discover
    elisa
    kate
  ];

  environment.sessionVariables = {
    SSH_AUTH_SOCK = "/home/${username}/.1password/agent.sock";
    LIBRARY_PATH = "${pkgs.glibc}/lib:${pkgs.gcc.cc.lib}/lib";
  };

  systemd = {
    services = {
      dlm.wantedBy = [ "multi-user.target" ];
      nix-daemon.serviceConfig = {
        MemoryHigh = "32G";
        MemoryMax = "42G";
      };
    };

    # "Most software has the HIP libraries hard-coded. You can work around it on NixOS by using:"
    tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
      ];
    };
    bluetooth.enable = true;
  };

  services = {
    # Enable X11/Wayland and KDE Plasma 6 desktop environment
    displayManager.sddm.enable = true;
    xserver = {
      enable = true;
      displayManager.sessionCommands = ''
        ${lib.getBin pkgs.xrandr}/bin/xrandr --setprovideroutputsource 2 0
      '';
      videoDrivers = [
        "amdgpu"
        "displaylink"
        "modesetting"
      ];
    };
    desktopManager.plasma6.enable = true;

    # Enable sound with PipeWire (recommended for Plasma 6)
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      extraConfig.pipewire."99-pulsemeeter" = {
        "context.properties" = {
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 512;
          "default.clock.max-quantum" = 2048;
        };
      };
    };
    # Disable PulseAudio as it conflicts with PipeWire
    pulseaudio.enable = false;

    blueman.enable = true;

    # Enable printing
    printing = {
      enable = true;
      drivers = with pkgs; [
        gutenprint
        hplip
        hplipWithPlugin
      ];
    };
    samba.enable = true;

    # Enable firmware updates
    fwupd.enable = true;

    # Enable flatpak
    flatpak.enable = true;
  };

  # Workaround NixOS 26.05 race: random-encrypted swap mkswap finishes but the
  # dm-crypt mapper stays at SYSTEMD_READY=0, so the generated .swap unit waits
  # 90s for its .device dep and fails. Re-trigger udev probing after mkswap.
  # https://github.com/NixOS/nixpkgs/issues/524389
  systemd.services."mkswap-dev-disk-byx2dpartuuid-0a44e123x2d0bfax2d48c5x2d80c0x2d7215f00162b1".serviceConfig.ExecStartPost =
    [
      "${pkgs.systemd}/bin/udevadm trigger --action=change /dev/mapper/dev-disk-byx2dpartuuid-0a44e123x2d0bfax2d48c5x2d80c0x2d7215f00162b1"
      "${pkgs.systemd}/bin/udevadm settle"
    ];

  # The Kingston NV3 (SNV3S1000G, DRAM-less SM2268XT2 controller) at PCI
  # 0000:07:00.0 is failing: it intermittently drops off the bus (lsblk shows
  # the disk as 0B) and its nvme_suspend callback returns -EBUSY, which aborts
  # every system suspend ("PM: Some devices failed to suspend ... Device or
  # resource busy") and bounces the session straight back to the lock screen.
  # Unbind the dead drive from the nvme driver at boot so it can't block
  # suspend; its data3 mount has been dropped from secrets/data-drives.nix.
  # Only this PCI address is touched — the other three NVMe drives stay bound.
  # Re-enable by deleting this service and rebooting (or PCI-rebinding).
  systemd.services.disable-kingston-nvme = {
    description = "Unbind failing Kingston NV3 NVMe (0000:07:00.0) that blocks suspend";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "disable-kingston-nvme" ''
        dev=0000:07:00.0
        if [ -e "/sys/bus/pci/drivers/nvme/$dev" ]; then
          echo "$dev" > /sys/bus/pci/drivers/nvme/unbind
        fi
      '';
    };
  };

  # Unload DisplayLink evdi module before suspend to prevent freeze
  systemd.services.displaylink-suspend = {
    description = "Unload evdi before suspend, reload after resume";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    unitConfig.StopWhenUnneeded = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.kmod}/bin/modprobe -r evdi";
      ExecStop = "${pkgs.kmod}/bin/modprobe evdi";
    };
  };

  # Rootless Docker
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  users.extraGroups.docker.members = [ "${username}" ];
  users.extraGroups.kvm.members = [ "${username}" ];

  # Enable XDG desktop portal for better application integration
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };

  # Run AppImages directly, registering a binfmt handler so they execute
  # without an explicit interpreter invocation.
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  security.rtkit.enable = true;

  # Allow KDE's Sleep menu entry to suspend when multiple sessions exist
  # (SDDM greeter + user session). The physical power button goes through
  # logind directly and bypasses polkit, which is why it already works.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.freedesktop.login1.suspend" ||
           action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
           action.id == "org.freedesktop.login1.hibernate" ||
           action.id == "org.freedesktop.login1.hibernate-multiple-sessions") &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # Additional system packages
  environment.systemPackages = with pkgs; [
    # Drivers
    unstable.displaylink

    # System utils
    clinfo
    mesa-demos # replaces glxinfo
    gparted
    btop-rocm
    ntfs3g
    pciutils
    usbutils

    # KDE specific packages for Plasma 6
    kdePackages.ark
    kdePackages.dolphin
    kdePackages.gwenview
    kdePackages.konsole
    kdePackages.spectacle
    freerdp
    # 25.11 ships kdotool 0.2.2-pre which has an off-by-one IPC bug
    # against KDE Plasma 6.5+: loadScript returns N but the actual
    # D-Bus object path is /Scripting/Script(N-1), so windowactivate
    # fails with "No such object path '/Scripting/Script1'". Fixed in
    # 0.2.3 which is in unstable.
    unstable.kdotool

    # Keyboard configurator
    vial
  ];

  # Fonts
  fonts.packages = [
    fonts.berkeley-mono-nerd-font
  ];
}
