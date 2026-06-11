# RackNerd VPS running atticd (binary cache server). Bridged den entity:
# legacy module tree imported as-is, specialArgs injected via instantiate +
# hm extraSpecialArgs (see modules/_lib/legacy-args.nix).
{ inputs, den, ... }:
let
  meta = import ../_lib/meta.nix;
  specialArgs = (import ../_lib/legacy-args.nix { inherit inputs; }) // {
    hostname = "racknerd-cloud-agent";
  };
in
{
  den.hosts.x86_64-linux.racknerd-cloud-agent = {
    users.${meta.username} = { };
    instantiate =
      args:
      inputs.nixpkgs.lib.nixosSystem (
        args // { specialArgs = (args.specialArgs or { }) // specialArgs; }
      );
  };

  den.aspects.racknerd-cloud-agent = {
    includes = [ den.aspects.hm-settings ];

    nixos = {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.nix-index-database.nixosModules.default
        inputs.attic.nixosModules.atticd
        inputs.agenix.nixosModules.default
        # > Our main nixos configuration <
        ../../hosts/racknerd-cloud
      ];

      home-manager = {
        extraSpecialArgs = specialArgs;
        users.${meta.username} = import ../../hosts/racknerd-cloud/home-manager.nix;
      };

      age.secrets.atticd-env = {
        file = "${inputs.dotfiles-secrets}/atticd.env.age";
        mode = "0400";
        owner = "root";
        group = "root";
      };
      age.identityPaths = [ "/home/${meta.username}/.ssh/id_rsa" ];
    };
  };
}
