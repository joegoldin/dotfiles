# Separate, userspace tailnet node: the initrd never listens for SSH on the LAN.
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  keys = import "${inputs.dotfiles-secrets}/keys.nix";
in
{
  den.aspects.elphael.nixos =
    { config, pkgs, ... }:
    let
      tailscale = config.services.tailscale.package;
      stateFile = "/etc/secrets/initrd/elphael-unlock.state";
      hostKey = "/etc/secrets/initrd/elphael-unlock_ed25519_key";
      # The admin-console policy must restrict this tag before enrollment.
      upFlags = "--hostname=elphael-unlock --advertise-tags=tag:ssh-in-only --accept-dns=false --accept-routes=false --ssh=false";
      enroll = pkgs.writeShellApplication {
        name = "elphael-unlock-enroll";
        runtimeInputs = [
          tailscale
          pkgs.openssh
          pkgs.coreutils
        ];
        text = ''
          if [ "$(id -u)" -ne 0 ]; then
            echo "Run as root: sudo elphael-unlock-enroll" >&2
            exit 1
          fi
          echo "Before continuing, configure tag:ssh-in-only in the Tailscale access policy:"
          echo "  Allow only your clients -> tag:ssh-in-only on TCP 222."
          echo "  Remove any broad rules that let this tag initiate tailnet connections."
          read -r -p "Have you applied and tested that policy? Type yes: " policyReady
          if [ "$policyReady" != yes ]; then
            echo "Enrollment cancelled; configure the tailnet policy first." >&2
            exit 1
          fi
          umask 077
          install -d -m 0700 /etc/secrets/initrd
          if [ ! -f ${hostKey} ]; then
            ssh-keygen -q -t ed25519 -N "" -f ${hostKey}
          fi
          work=$(mktemp -d /run/elphael-unlock-enroll.XXXXXX)
          pid=""
          cleanup() {
            if [ -n "$pid" ]; then
              kill "$pid" 2>/dev/null || true
              wait "$pid" || true
            fi
            rm -rf "$work"
          }
          trap cleanup EXIT
          # Do not reuse the running system's node, socket, or TPM-encrypted state.
          tailscaled --tun=userspace-networking --port=0 --encrypt-state=false \
            --state=${stateFile} --socket="$work/tailscaled.sock" \
            >"$work/tailscaled.log" 2>&1 &
          pid=$!
          for _ in $(seq 1 100); do
            if [ -S "$work/tailscaled.sock" ]; then break; fi
            if ! kill -0 "$pid" 2>/dev/null; then
              echo "Enrollment daemon failed (check that the configured Tailscale package runs on this host)." >&2
              exit 1
            fi
            sleep 0.1
          done
          tailscale --socket="$work/tailscaled.sock" up --timeout=10m ${upFlags}
          tailscale --socket="$work/tailscaled.sock" serve --bg --yes --tcp=222 tcp://127.0.0.1:222
          echo "Enrolled elphael-unlock. Disable its key expiry in Tailscale, then run just boot."
        '';
      };
    in
    {
      environment.systemPackages = [ enroll ];
      system.build.elphaelUnlockEnroll = enroll;

      boot.initrd = {
        availableKernelModules = [ "igc" ];
        network = {
          enable = true;
          ssh = {
            enable = true;
            port = 222;
            authorizedKeys = [ keys.${meta.username} ];
            hostKeys = [ hostKey ];
            # Serve forwards to loopback; there is no physical-interface listener.
            extraConfig = ''
              ListenAddress 127.0.0.1
              AllowTcpForwarding no
              X11Forwarding no
              PermitTunnel no
            '';
          };
        };
        # Strings (not Nix paths): copied by the bootloader on the target, never
        # imported into the world-readable store. Both are dedicated initrd keys.
        secrets."/var/lib/tailscale/tailscaled.state" = stateFile;
        services.resolved.enable = true;
        systemd = {
          enable = true;
          network.networks."10-unlock-wired" = {
            matchConfig.MACAddress = "04:7c:16:76:d0:3c";
            networkConfig.DHCP = "ipv4";
          };
          contents."/etc/motd".text = ''

            elphael: encrypted root is LOCKED.
            Run: unlock
            Enter the disk passphrase to finish booting; this session then closes.

          '';
          storePaths = [ tailscale ];
          services.tailscaled-unlock = {
            description = "Tailnet-only pre-boot unlock transport";
            wantedBy = [ "initrd.target" ];
            after = [
              "network.target"
              "initrd-nixos-copy-secrets.service"
            ];
            before = [ "shutdown.target" ];
            conflicts = [ "shutdown.target" ];
            unitConfig.DefaultDependencies = false;
            serviceConfig = {
              Type = "simple";
              RuntimeDirectory = "tailscale";
              StateDirectory = "tailscale";
              UMask = "0077";
              ExecStart = "${tailscale}/bin/tailscaled --tun=userspace-networking --port=0 --encrypt-state=false --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock";
              Restart = "on-failure";
              RestartSec = 5;
            };
          };
          services.tailscale-unlock-serve = {
            description = "Forward tailnet port 222 to loopback SSH";
            wantedBy = [ "initrd.target" ];
            requires = [ "tailscaled-unlock.service" ];
            after = [
              "tailscaled-unlock.service"
              "sshd.service"
            ];
            before = [ "shutdown.target" ];
            conflicts = [ "shutdown.target" ];
            unitConfig.DefaultDependencies = false;
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              Restart = "on-failure";
              RestartSec = 5;
            };
            script = ''
              ${tailscale}/bin/tailscale up --timeout=60s ${upFlags}
              ${tailscale}/bin/tailscale serve --bg --yes --tcp=222 tcp://127.0.0.1:222
            '';
          };
        };
      };
    };
}
