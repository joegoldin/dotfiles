# Oracle Cloud bastion (pelican game servers + tailnet entry). Bridged den
# entity: the module tree under hosts/oracle-cloud is imported as-is and the
# legacy specialArgs are injected via the instantiate override + hm
# extraSpecialArgs — exactly what the old flake.nix block did. Entity name
# (flake output) stays oracle-cloud-bastion; the machine's hostName is
# "bastion" (set by hosts/oracle-cloud from the hostname specialArg).
{ inputs, den, ... }:
let
  meta = import ../_lib/meta.nix;
  specialArgs = (import ../_lib/legacy-args.nix { inherit inputs; }) // {
    hostname = "bastion";
  };
in
{
  den.hosts.x86_64-linux.oracle-cloud-bastion = {
    hostName = "bastion";
    users.${meta.username} = { };
    # Legacy module trees consume specialArgs; merge them into whatever den
    # passes to nixosSystem.
    instantiate =
      args:
      inputs.nixpkgs.lib.nixosSystem (
        args // { specialArgs = (args.specialArgs or { }) // specialArgs; }
      );
  };

  den.aspects.oracle-cloud-bastion = {
    includes = [ den.aspects.hm-settings ];

    nixos = {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.nix-index-database.nixosModules.default
        inputs.pelican.nixosModules.default
        inputs.agenix.nixosModules.default
        # > Our main nixos configuration <
        ../../hosts/oracle-cloud
      ];

      nixpkgs.overlays = [ inputs.pelican.overlays.default ];

      home-manager = {
        extraSpecialArgs = specialArgs;
        users.${meta.username} = import ../../hosts/oracle-cloud/home-manager.nix;
      };

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
      age.identityPaths = [ "/home/${meta.username}/.ssh/id_ed25519" ];
    };
  };
}
