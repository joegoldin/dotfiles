# Base system config (UEFI systemd-boot, ssh, fail2ban). erdtree is a UEFI Dell
# server; the ESP + LUKS root layout lives in _disk-config.nix.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.aspects.erdtree.nixos =
    { lib, pkgs, ... }:
    {
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      # UEFI boot via systemd-boot (ESP mounted at /boot by disko).
      boot.loader = {
        systemd-boot.enable = lib.mkForce true;
        efi.canTouchEfiVariables = true;
      };

      users.users.${meta.username}.extraGroups = [
        "audio"
        "video"
        "docker"
      ];

      programs = {
        zsh.enable = true;
        fish.enable = true;
        # ld for vscode server
        nix-ld = {
          enable = true;
          package = pkgs.nix-ld;
        };
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
          # Forbid root SSH on the booted system — admin is joe + passwordless
          # sudo, and the initrd LUKS-unlock uses its own separate sshd. (A
          # re-install targets a fresh/rescue image, or nixos-anywhere over joe@.)
          PermitRootLogin = "no";
          # Opinionated: use keys only.
          PasswordAuthentication = false;
        };
      };

      # Brute-force protection for the public host (default sshd jail).
      services.fail2ban = {
        enable = true;
        bantime = "1h";
        bantime-increment = {
          enable = true;
          maxtime = "24h";
        };
      };

      # Nix store maintenance. erdtree is a 931 GB build + game host that churns
      # a lot of closures (garnix CI), so keep the store from crowding out
      # everything else: run our own daily job instead of the shared nix.gc so
      # the 14-day retention pass and the hard ~250 GiB cap run in sequence, not
      # racing each other.
      nix.gc.automatic = lib.mkForce false;

      systemd.services.nix-store-maintenance = {
        description = "Daily nix GC: 14-day generation retention + ~250 GiB store cap";
        path = [ pkgs.nix pkgs.coreutils ];
        serviceConfig = {
          Type = "oneshot";
          # Low priority so it never fights an active build for IO/CPU.
          IOSchedulingClass = "idle";
          Nice = 19;
        };
        script = ''
          set -eu
          cap=$(( 250 * 1024 * 1024 * 1024 ))   # 250 GiB
          # 1) Delete system/user generations (and their now-dead closures)
          #    older than 14 days.
          nix-collect-garbage --delete-older-than 14d
          # 2) If the store is still over the cap, free the excess. --max-freed
          #    deletes remaining unreferenced paths until that many bytes are
          #    freed, then stops. (Rooted paths — the live system closure and the
          #    last 14 days of generations — are never touched, so the store can
          #    settle slightly above the cap if those alone exceed it, which is
          #    the safe behaviour.) du -sb is the accurate on-disk size.
          used=$(du -sb /nix/store | cut -f1)
          if [ "$used" -gt "$cap" ]; then
            nix-collect-garbage --max-freed $(( used - cap ))
          fi
        '';
      };
      systemd.timers.nix-store-maintenance = {
        description = "Schedule daily nix store maintenance";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true; # catch up on next boot if a daily run was missed
          RandomizedDelaySec = "45min";
        };
      };

      # Disk-pressure safety net: if free space runs low mid-build, let nix
      # auto-GC instead of filling the disk (independent of the daily job).
      nix.settings = {
        min-free = 20 * 1024 * 1024 * 1024; # start GC when < 20 GiB free
        max-free = 60 * 1024 * 1024 * 1024; # free until 60 GiB available
      };
    };
}
