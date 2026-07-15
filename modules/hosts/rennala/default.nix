# RackNerd VPS running atticd (binary cache server). Lean home environment;
# no home-baseline; the universal features ride on the joe user aspect.
# Aspect content lives in the sibling files (system.nix, machine.nix,
# attic-server.nix, home.nix).
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
        inputs.attic.nixosModules.atticd
        inputs.agenix.nixosModules.default
        ./_disk-config.nix
        ./_hardware-configuration.nix
      ];

      age.secrets.atticd-env = {
        file = "${inputs.dotfiles-secrets}/atticd.env.age";
        mode = "0400";
        owner = "root";
        group = "root";
      };
      age.secrets.umans_api_key = {
        file = "${inputs.dotfiles-secrets}/umans_api_key.age";
        mode = "0400";
        owner = meta.username;
      };
      age.identityPaths = [ "/home/${meta.username}/.ssh/id_rsa" ];
    };
  };
}
