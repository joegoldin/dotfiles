# RackNerd VPS running atticd (binary cache server). Lean home environment —
# does not pull in the shared home baseline (too large for the VPS disk).
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.hosts.x86_64-linux.racknerd-cloud-agent.users.${meta.username} = { };

  den.aspects.racknerd-cloud-agent = {
    includes = [ den.aspects.hm-settings ];

    nixos = {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.nix-index-database.nixosModules.default
        inputs.attic.nixosModules.atticd
        inputs.agenix.nixosModules.default
        ./_attic.nix
        ./_configuration.nix
        ./_disk-config.nix
        ./_hardware-configuration.nix
        ./_racknerd-cloud.nix
        ./_services.nix
      ];

      _module.args.hostname = "racknerd-cloud-agent";

      age.secrets.atticd-env = {
        file = "${inputs.dotfiles-secrets}/atticd.env.age";
        mode = "0400";
        owner = "root";
        group = "root";
      };
      age.identityPaths = [ "/home/${meta.username}/.ssh/id_rsa" ];
    };

    provides.to-users.homeManager = {
      imports = [ ./_home-manager.nix ];
    };
  };
}
