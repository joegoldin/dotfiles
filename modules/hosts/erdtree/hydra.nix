{ inputs, ... }:
let
  inherit (inputs) dotfiles-secrets;
  caches = import ../../_lib/ci-caches.nix inputs;
  keys = import "${dotfiles-secrets}/keys.nix";
  domains = import "${dotfiles-secrets}/domains.nix";
in
{
  den.aspects.erdtree.nixos =
    { config, pkgs, ... }:
    let
      features = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
        "recursive-nix"
      ];
      loopback = "127.0.0.1";
    in
    {
      # Keep the existing cache signing identity and the pre-authorized ARM
      # builder identity across the cutover. Neither key goes into the store.
      age.secrets = {
        hydra-cache-signing-key = {
          file = "${dotfiles-secrets}/garnix-cache-priv-key.age";
          owner = "hydra-www";
        };
        hydra-arm-builder-key = {
          file = "${dotfiles-secrets}/garnix-remote-builder-ssh.age";
          owner = "hydra-queue-runner";
        };
      };

      services.hydra = {
        enable = true;
        inherit (caches) hydraURL;
        listenHost = loopback;
        notificationSender = "hydra@erdtree";
        useSubstitutes = true;
        minimumDiskFree = 40;
        minimumDiskFreeEvaluator = 25;
        extraConfig = ''
          binary_cache_secret_key_file = ${config.age.secrets.hydra-cache-signing-key.path}
        '';
      };
      # Keep the existing PG18 data directory; Hydra creates a separate DB.
      services.postgresql = {
        package = pkgs.postgresql_18;
        enableTCPIP = false;
      };
      systemd.services = {
        hydra-tailnet = caches.serve {
          inherit config;
          backend = "http://${loopback}:${toString config.services.hydra.port}";
          port = caches.hydraPort;
          unit = "hydra-server";
        };

        # Provision this file on the host with a narrowly scoped read token for
        # private flake inputs. The queue runner and builds don't get the token.
        hydra-evaluator.environment.NIX_USER_CONF_FILES = "/var/lib/hydra/github-nix.conf";
        hydra-queue-runner = {
          restartTriggers = [ config.age.secrets.attic-netrc.file ];
          serviceConfig.LoadCredential = "celler-netrc:${caches.cellerNetrc}";
          environment.NIX_CONFIG = ''
            netrc-file = /run/credentials/hydra-queue-runner.service/celler-netrc
          '';
        };

        # Keep encrypted-root writes and build memory from starving other work.
        nix-daemon.serviceConfig = {
          CPUQuota = "1600%";
          IOWriteBandwidthMax = "/dev/mapper/cryptroot 41943040";
          MemoryHigh = "115G";
          MemoryMax = "125G";
        };
      };
      nix.settings = {
        allowed-uris = domains.hydraAllowedUris;
        system-features = features;
        cores = 4;
      };
      nix.buildMachines = [
        {
          hostName = "localhost";
          system = "x86_64-linux";
          protocol = null;
          maxJobs = 6;
          supportedFeatures = features;
        }
        {
          hostName = caches.armBuilder;
          system = "aarch64-linux";
          # Hydra uses the legacy nix-store --serve protocol for remote builds.
          protocol = "ssh";
          sshUser = "nix-ssh";
          sshKey = config.age.secrets.hydra-arm-builder-key.path;
          maxJobs = 1;
          supportedFeatures = [ "big-parallel" ];
        }
      ];
      programs.ssh.knownHosts.${caches.armBuilder}.publicKey = keys.farum-azula;

    };
}
