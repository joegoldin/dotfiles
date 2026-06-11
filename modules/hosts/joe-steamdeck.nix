# Steam Deck with Jovian NixOS. Bridged den entity: legacy module tree
# imported as-is, specialArgs injected via instantiate + hm extraSpecialArgs
# (see modules/_lib/legacy-args.nix).
{ inputs, den, ... }:
let
  meta = import ../_lib/meta.nix;
  specialArgs = (import ../_lib/legacy-args.nix { inherit inputs; }) // {
    hostname = "joe-steamdeck";
  };
in
{
  den.hosts.x86_64-linux.joe-steamdeck = {
    users.${meta.username} = { };
    instantiate =
      args:
      inputs.nixpkgs.lib.nixosSystem (
        args // { specialArgs = (args.specialArgs or { }) // specialArgs; }
      );
  };

  den.aspects.joe-steamdeck = {
    includes = [ den.aspects.hm-settings ];

    nixos = {
      imports = [
        inputs.jovian-nixos.nixosModules.default
        inputs.nix-index-database.nixosModules.default
        inputs.nix-attic-infra.nixosModules.attic-post-build-hook
        inputs.agenix.nixosModules.default
        ../../hosts/steamdeck
      ];

      home-manager = {
        extraSpecialArgs = specialArgs;
        sharedModules = [
          inputs.plasma-manager.homeModules.plasma-manager
          inputs.nix-attic-infra.homeManagerModules.attic-client
        ];
        users.${meta.username} = import ../../hosts/steamdeck/home-manager.nix;
      };

      age.secrets.attic-netrc = {
        file = "${inputs.dotfiles-secrets}/attic-netrc.age";
        mode = "0400";
        owner = meta.username;
      };
      age.secrets.attic-token = {
        file = "${inputs.dotfiles-secrets}/attic.token.age";
        mode = "0400";
        owner = meta.username;
      };
    };
  };
}
