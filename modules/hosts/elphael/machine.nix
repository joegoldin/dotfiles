# hosts/nixos/system/elphael.nix
# Specific configuration for elphael tower machine
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  dotfiles-assets = inputs.dotfiles-assets;
  username = meta.username;
in
{
  den.aspects.elphael.nixos =
    {
      pkgs,
      lib,
      ...
    }:
    let
      fonts = import ../../_data/fonts { inherit pkgs lib dotfiles-assets; };
      displaylinkWedgeWatchdog = pkgs.writeShellApplication {
        name = "displaylink-wedge-watchdog";
        runtimeInputs = with pkgs; [
          coreutils
          gnugrep
          systemd
        ];
        text = builtins.readFile ./_displaylink-wedge-watchdog.sh;
      };
      displaylinkSuspendSettle = pkgs.writeShellApplication {
        name = "displaylink-suspend-settle";
        runtimeInputs = with pkgs; [
          coreutils
          gnugrep
          procps
        ];
        text = builtins.readFile ./_displaylink-suspend-settle.sh;
      };
      desktopIoLatency = pkgs.writeShellApplication {
        name = "desktop-io-latency";
        runtimeInputs = with pkgs; [
          coreutils
          util-linux
        ];
        text = builtins.readFile ./_desktop-io-latency.sh;
      };
    in
    {
      # Cap nix builds: 3 parallel jobs × 6 threads each = 18 max threads. Memory
      # is throttled at 32 GiB (MemoryHigh, soft) with a 42 GiB hard ceiling
      # (MemoryMax) on the nix-daemon cgroup; High slows builds down via reclaim
      # pressure rather than OOM-killing them, while Max keeps a single runaway
      # link step from taking down the whole 64 GiB box.
      nix.settings.max-jobs = 3;
      nix.settings.cores = 6;

      # Keep a write storm from stalling the desktop. A Steam extraction, a
      # nix-gc unlink run or the swapfile dd used to hang KWin's main thread for
      # seconds at a time, with jbd2, dmcrypt_write and every process that
      # touched the disk parked in D state behind them. On the 9.6-day uptime,
      # 10 of the 13 KWin hangs landed inside the nix-gc that deleted 21563
      # store paths, and ncro logged SQLite writes taking up to 47.9s.
      #
      # The ratio defaults are a share of RAM, so on 62 GiB they let 12.5 GiB of
      # dirty pages pile up before writeback is forced and flushing that through
      # LUKS takes tens of seconds. Bound it in bytes instead: writeback starts
      # early and the worst-case flush drains in well under a second. Setting
      # dirty_bytes zeroes dirty_ratio, which is what we want.
      boot.kernel.sysctl = {
        "vm.dirty_background_bytes" = 256 * 1024 * 1024;
        "vm.dirty_bytes" = 1024 * 1024 * 1024;

        # At the default 60 the kernel treats app memory and page cache as
        # roughly equally evictable, so streaming a game's assets through the
        # cache pushes idle applications out to swap: measured 4.5 GiB of
        # anonymous memory on disk against 10.3 GiB resident - 30% of it - while
        # 40 GiB of never-reused Inactive(file) was retained, on a box sitting at
        # 23% memory use. Alt-tabbing back then faults it all in and stutters.
        # Prefer dropping that cache; swap stays as a reserve, not routine.
        "vm.swappiness" = 10;

        # Swap readahead faults in 2^page-cluster pages at a time, which pays
        # for itself on a seeking queue and not at all here. With zswap in
        # front (below) the 8 GiB backing partition compresses to well inside
        # the pool, so nearly every swap-in is a pool hit and the default 3
        # spends 8 decompressions to satisfy one fault. Fault them in singly.
        "vm.page-cluster" = 0;

        # kswapd wakes at the low watermark and reclaims up to high; cross min
        # before it catches up and the allocating thread reclaims for itself,
        # which is where a burst turns into a visible stall. Both gaps are
        # managed_pages * this / 10000, and the default 10 leaves 62 MiB of the
        # Normal zone's 60.9 GiB between low and min - about 30ms of runway
        # against a nix build allocating at a couple GB/s. zswap widens the
        # need further, since reclaiming an anonymous page is now a zstd
        # compression (~1 GB/s on kswapd's single thread) rather than dropping
        # a clean one. 200 buys 1.22 GiB of runway for 2% of RAM on a box that
        # idles with 34 GiB free. Past ~500 kswapd just evicts page cache to
        # hold reserve it never uses.
        "vm.watermark_scale_factor" = 200;
      };

      # Swap here is an 8 GiB random-encrypted partition, so every swap-in
      # pays dm-crypt plus NVMe and queues behind whatever dmcrypt_write is
      # already draining - the same D-state pile-up the dirty_bytes caps above
      # exist to break. zswap puts a compressed RAM cache in front of it:
      # reclaimed anonymous pages are zstd'd into a pool capped at 20% of RAM
      # (12.4 GiB, more than the whole backing partition holds uncompressed),
      # and faulting one back is a decompression rather than a decrypt-and-
      # read. Only what the pool evicts ever reaches the disk.
      #
      # Unlike zram the pool is not preallocated - it grows on demand and
      # shrinks again - so RAM the session is not swapping stays available to
      # it, which matters more at 62 GiB than the extra ratio zram would buy.
      #
      # shrinker_enabled is off in this kernel's defconfig
      # (CONFIG_ZSWAP_SHRINKER_DEFAULT_ON unset). Without it the pool only
      # writes back once it is full, and a full pool rejects new pages
      # straight to disk in the middle of reclaim - precisely the stall being
      # avoided. With it, cold pages drain to the partition in the background
      # under pressure so the pool keeps headroom for the hot ones.
      boot.kernelParams = [
        "zswap.enabled=1"
        "zswap.shrinker_enabled=1"
        # Both already match this kernel's build defaults; pinned so an
        # upstream defconfig change cannot silently retune reclaim. zsmalloc
        # is the only zpool left as of 6.16, so there is no zpool to set.
        "zswap.compressor=zstd"
        "zswap.max_pool_percent=20"
      ];

      # NVMe defaults to "none", which is the throughput choice but gives the
      # compositor's small writes no priority over a bulk writer holding 1023
      # queued requests. mq-deadline costs little here and honours the idle
      # ioprio set on nix-gc below, which "none" ignores outright.
      services.udev.extraRules = ''
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="mq-deadline"
      '';

      # nix-gc is pure background work with no deadline, so stop it competing
      # with the session it interrupts; nix-daemon already has the equivalent
      # memory ceilings. IOSchedulingClass is the knob that bites, and only
      # because of the mq-deadline switch above - IOWeight stays inert until
      # something enables bfq or iocost, and is kept for that day.
      systemd.services.nix-gc.serviceConfig = {
        IOSchedulingClass = "idle";
        IOWeight = 10;
        CPUWeight = 20;
        Nice = 19;
      };

      systemd.services.desktop-io-latency = {
        description = "Protect the desktop session from background I/O storms";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = lib.getExe desktopIoLatency;
        };
      };

      # The io.latency on user.slice above only throttles its siblings -
      # system.slice, home of nix builds and nix-gc. It is blind to a writer
      # inside user.slice itself, and that is exactly where a Steam download
      # to /home runs (app.slice, next to the compositor's session.slice
      # under the same user manager). Give session.slice its own latency
      # target on the root device so the io controller throttles app.slice
      # when kwin starts missing it. The user manager already delegates the
      # io controller, so the target lands on a writable cgroup.
      systemd.user.units."session.slice" = {
        overrideStrategy = "asDropin";
        text = ''
          [Slice]
          IODeviceLatencyTargetSec=/dev/mapper/luks-bf7e5885-6a8e-447b-bb6d-b682b2991325 50ms
        '';
      };

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
      # Only this PCI address is touched; the other three NVMe drives stay bound.
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

      # DisplayLink (evdi) freezes the whole KWin/Wayland session on resume: after
      # waking from S3 the AMD outputs restore in ~13ms, but the evdi virtual
      # outputs stay dead until DisplayLinkManager re-establishes its USB link
      # (~16s). KWin's single render loop blocks on those stale outputs the entire
      # time ("Pageflip timed out! This is a bug in the evdi kernel driver" ...
      # "Pageflip arrived after all, 16730ms after the commit"), so the desktop is
      # frozen even though the real monitors are already painting.
      #
      # The previous version only ran `modprobe -r evdi`, which fails on EVERY
      # suspend ("Module evdi is in use") because dlm.service (DisplayLinkManager),
      # Xwayland and other clients hold the evdi cards (/dev/dri/card0, card2) open,
      # so it never actually did anything.
      #
      # Fix: stop DisplayLinkManager before sleep so it cleanly tears down the
      # virtual outputs (nothing stale for KWin to hang on), then bring it back
      # after resume. The evdi unload/reload is kept only as best-effort (the `-`
      # prefix ignores failure) for the rare case nothing holds it; its failure no
      # longer aborts the unit, so ExecStop still runs and DisplayLink always
      # returns on resume.
      #
      # The teardown is gated behind displaylink-suspend-settle because logind
      # broadcasts PrepareForSleep to this unit and to KScreenLocker at once: when
      # the two overlap the greeter crashes in PlasmaQuick and the lock screen is
      # unusable on resume. See _displaylink-suspend-settle.sh for the mechanism.
      systemd.services.displaylink-suspend = {
        description = "Stop DisplayLink before suspend, restart it after resume";
        before = [ "sleep.target" ];
        wantedBy = [ "sleep.target" ];
        unitConfig.StopWhenUnneeded = true;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = [
            "${lib.getExe displaylinkSuspendSettle}"
            "-${pkgs.systemd}/bin/systemctl stop dlm.service"
            "-${pkgs.kmod}/bin/modprobe -r evdi"
          ];
          ExecStop = [
            "-${pkgs.kmod}/bin/modprobe evdi"
            "${pkgs.systemd}/bin/systemctl start dlm.service"
          ];
        };
      };

      # DPMS'ing the evdi output off stops the driver completing page flips, and
      # KWin then spins on "Pageflip timed out" once per second with the whole
      # desktop frozen - 11s, 22s, 28s, 5.6min and 15.3min over one 9.6-day
      # uptime, every episode starting 1s after "Notifying display power state:
      # off". Trigger on those log lines: KWin stays runnable throughout, so the
      # earlier scan for a task blocked in drm_atomic_helper_wait_for_flip_done
      # ran 24 times during the 5.6min freeze and matched nothing. Replaying the
      # journal, this detector fires on 9 of 9 probes inside real freezes and 0
      # of 8 in quiet periods.
      systemd.services.displaylink-wedge-watchdog = {
        description = "Restart DisplayLink after a persistent DRM page-flip wedge";
        after = [ "dlm.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe displaylinkWedgeWatchdog;
          TimeoutStartSec = "90s";
        };
      };

      systemd.timers.displaylink-wedge-watchdog = {
        description = "Check for a wedged DisplayLink DRM page flip";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = "15s";
          AccuracySec = "1s";
          Unit = "displaylink-wedge-watchdog.service";
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
    };
}
