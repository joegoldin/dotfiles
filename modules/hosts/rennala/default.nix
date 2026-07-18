# RackNerd VPS for the amia.live AI use case. Lean home environment;
# no home-baseline; the universal features ride on the joe user aspect.
# Aspect content lives in the sibling files (system.nix, machine.nix, home.nix).
# (Ran the fleet's atticd binary cache until Jul 2026; migrated to siofra.)
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.hosts.x86_64-linux.rennala.users.${meta.username} = { };

  den.aspects.rennala = {
    includes = [ den.aspects.nix-settings ];

    nixos = {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.agenix.nixosModules.default
        ./_disk-config.nix
        ./_hardware-configuration.nix
      ];

      age.secrets.umans_api_key = {
        file = "${inputs.dotfiles-secrets}/umans_api_key.age";
        mode = "0400";
        owner = meta.username;
      };
      age.identityPaths = [ "/home/${meta.username}/.ssh/id_rsa" ];
    };
  };
}
