# Erdtree — beefy dedicated server (2× E5-2670v2, 192 GB DDR3), gaming/HPC host.
# Calagopus Wings node (wings-rs) registered to the Calagopus panel on roundtable
# (unraid). Entity name (= flake output) and hostName are both "erdtree".
# Installed on bare metal via nixos-anywhere; lean home like rennala. Aspect
# content lives in the sibling files (system.nix, machine.nix, wings.nix, home.nix).
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.hosts.x86_64-linux.erdtree = {
    hostName = "erdtree";
    users.${meta.username} = { };
  };

  den.aspects.erdtree = {
    # Lean, like racknerd — no home-baseline. The attic/numtide-cache
    # substituter aspects are intentionally omitted: deploys build on the
    # build-host and copy the closure over ssh, so the server never builds.
    includes = [
      den.aspects.nix-settings
    ];

    nixos = {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.agenix.nixosModules.default
        ./_disk-config.nix
        ./_hardware-configuration.nix
      ];

      age.secrets.cf = {
        file = "${inputs.dotfiles-secrets}/erdtree-cf.json.age";
        mode = "655";
        owner = meta.username;
        group = "users";
      };
      age.secrets.umans_api_key = {
        file = "${inputs.dotfiles-secrets}/umans_api_key.age";
        mode = "0400";
        owner = meta.username;
      };
      # Decrypt with the machine's own SSH host key (present from first boot).
      # No user key needed — every secret this host uses is encrypted to
      # `systems`, so the host key (once added to `systems` + rekeyed) covers
      # them all. This also matches agenix's default when identityPaths is unset.
      age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };
}
