# Oracle Cloud bastion — tailnet entry (exit/subnet router) + cloudflared ingress
# + attic binary-cache client. Entity name (= flake output) and hostName are both
# "farum-azula". Pelican was removed (game servers migrated to Calagopus). Aspect
# content lives in the sibling files (system.nix, machine.nix, home.nix).
#
# NB: ./_attic.nix is intentionally not imported; the old tree never
# imported it either (dead file kept for reference).
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.hosts.x86_64-linux.farum-azula = {
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
      age.identityPaths = [ "/home/${meta.username}/.ssh/id_ed25519" ];
    };
  };
}
