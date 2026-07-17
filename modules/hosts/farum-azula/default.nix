# Oracle Cloud bastion — tailnet entry (exit/subnet router) + attic binary-cache
# client + a Calagopus Wings node (aarch64; Pelican was retired, this now runs
# wings-rs against the Calagopus panel; cloudflared removed). Entity name
# (= flake output) and hostName are both "farum-azula". Aspect content lives in the
# sibling files (system.nix, machine.nix, wings.nix, home.nix).
#
# NB: ./_attic.nix is intentionally not imported; the old tree never
# imported it either (dead file kept for reference).
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  # Oracle Cloud Ampere = aarch64 (A1.Flex). den.hosts groups the output under
  # aarch64; nixpkgs.hostPlatform is set to aarch64 in system.nix (must match, or
  # it conflicts with the generated hardware config).
  den.hosts.aarch64-linux.farum-azula = {
    hostName = "farum-azula";
    users.${meta.username} = { };
  };

  den.aspects.farum-azula = {
    includes = [
      den.aspects.nix-settings
      den.aspects.binary-caches
      den.aspects.numtide-cache
      den.aspects.home-baseline
    ];

    nixos = {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.agenix.nixosModules.default
        ./_disk-config.nix
        ./_hardware-configuration.nix
      ];

      age.secrets.attic-netrc = {
        file = "${inputs.dotfiles-secrets}/attic-netrc.age";
        mode = "0400";
      };
      age.secrets.umans_api_key = {
        file = "${inputs.dotfiles-secrets}/umans_api_key.age";
        mode = "0400";
        owner = meta.username;
      };
      # Decrypt with the machine's own SSH host key (seeded by deploy-farum-azula),
      # not a personal user key on a public box. After a fresh deploy, replace the
      # farum-azula key in keys.nix with the printed one and rekey.
      age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

      # Native aarch64 remote builder for the self-hosted garnix CI on erdtree.
      # Without this, erdtree builds aarch64 configs (farum-azula, scarab, …) by
      # emulating aarch64 via qemu — 10-50x slower. erdtree's nix-daemon connects
      # here as the nix-ssh user with the garnix builder key and builds natively.
      # `write` is required so the client can push derivation inputs / pull
      # outputs.
      nix.sshServe = {
        enable = true;
        protocol = "ssh-ng";
        write = true;
        keys = [ (import "${inputs.dotfiles-secrets}/garnix.nix").builderSshPubKey ];
      };
      # Remote builds push locally-built (unsigned) input closures from erdtree;
      # the daemon only accepts unsigned paths from trusted users, so without
      # this every erdtree-built dep fails with "cannot add path ... because it
      # lacks a signature by a trusted key". Cache-substituted inputs never hit
      # this (they carry cache.nixos.org's signature). Trusting nix-ssh trusts
      # exactly the holder of the garnix builder key above (erdtree's daemon).
      nix.settings.trusted-users = [ "nix-ssh" ];
    };
  };
}
