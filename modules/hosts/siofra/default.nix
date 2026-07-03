# Siofra — 16 GB misc-cloud VPS (107.174.45.13). Runs a Calagopus Wings node
# (wings-rs) registered to the panel on roundtable (converted from Pelican Wings
# in place). Entity name (= flake output) and hostName are both "siofra".
# Installed via nixos-anywhere; lean home like racknerd. Aspect content lives in
# the sibling files (system.nix, machine.nix, wings.nix, home.nix).
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.hosts.x86_64-linux.siofra = {
    hostName = "siofra";
    users.${meta.username} = { };
  };

  den.aspects.siofra = {
    # Lean, like racknerd — no home-baseline. The attic/numtide-cache
    # substituter aspects are intentionally omitted: deploys build on the
    # build-host and copy the closure over ssh, so the server never builds.
    includes = [
      den.aspects.nix-settings
    ];

    nixos = {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.nix-index-database.nixosModules.default
        inputs.agenix.nixosModules.default
        ./_disk-config.nix
        ./_hardware-configuration.nix
      ];

      age.secrets.cf = {
        file = "${inputs.dotfiles-secrets}/siofra-cf.json.age";
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
