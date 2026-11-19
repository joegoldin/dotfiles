{ den, ... }:
{
  den.aspects = {
    # Opt in on RAM-rich machines with bursty buffered writers. These are
    # dirty-page thresholds, not a device bandwidth or flush-latency guarantee.
    bounded-writeback.nixos = { lib, ... }: {
      boot.kernel.sysctl = {
        "vm.dirty_background_bytes" = lib.mkDefault (256 * 1024 * 1024);
        "vm.dirty_bytes" = lib.mkDefault (1024 * 1024 * 1024);
      };
    };

    # For a desktop with a block-backed root and a systemd user session.
    desktop-io = {
      includes = [ den.aspects.bounded-writeback ];
      nixos =
        {
          config,
          pkgs,
          lib,
          ...
        }:
        let
          desktopIoLatency = pkgs.writeShellApplication {
            name = "desktop-io-latency";
            runtimeInputs = with pkgs; [
              coreutils
              util-linux
            ];
            text = builtins.readFile ./_desktop-io/_desktop-io-latency.sh;
          };
        in
        {
          systemd = {
            services = {
              # Idle GC priority is effective with Elphael's mq-deadline scheduler;
              # selecting this policy does not change a device's scheduler.
              nix-gc.serviceConfig = {
                IOSchedulingClass = "idle";
                IOWeight = 10;
                CPUWeight = 20;
                Nice = 19;
              };

              desktop-io-latency = {
                description = "Protect the desktop session from background I/O storms";
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  ExecStart = lib.getExe desktopIoLatency;
                };
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
            user.units."session.slice" = {
              overrideStrategy = "asDropin";
              text = ''
                [Slice]
                IODeviceLatencyTargetSec=${config.fileSystems."/".device} 50ms
              '';
            };
          };
        };
    };

    # Measure the daemon that performs builds, not just the CI frontend.
    # Accounting alone does not throttle builds or change storage defaults.
    build-host-io.nixos = {
      systemd.services.nix-daemon.serviceConfig.IOAccounting = true;
    };
  };
}
