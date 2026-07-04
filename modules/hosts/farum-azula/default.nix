# Oracle Cloud bastion — tailnet entry (exit/subnet router) + cloudflared ingress
# + attic binary-cache client + a Calagopus Wings node (aarch64; Pelican was
# retired, this now runs wings-rs against the Calagopus panel). Entity name
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
      den.aspects.attic
      den.aspects.numtide-cache
      den.aspects.home-baseline
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
        file = "${inputs.dotfiles-secrets}/cf.json.age";
        mode = "655";
        owner = meta.username;
        group = "users";
      };
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
    };
  };
}
