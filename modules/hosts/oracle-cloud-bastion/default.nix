# Oracle Cloud bastion (pelican game servers + tailnet entry). Entity name
# (= flake output) is oracle-cloud-bastion; the machine's hostName is
# "bastion". Aspect content lives in the sibling files (system.nix,
# machine.nix, pelican.nix, home.nix).
#
# NB: ./_attic.nix is intentionally not imported — the old tree never
# imported it either (dead file kept for reference).
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.hosts.x86_64-linux.oracle-cloud-bastion = {
    hostName = "bastion";
    users.${meta.username} = { };
  };

  den.aspects.oracle-cloud-bastion = {
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
        inputs.pelican.nixosModules.default
        inputs.agenix.nixosModules.default
        ./_disk-config.nix
        ./_hardware-configuration.nix
      ];

      nixpkgs.overlays = [ inputs.pelican.overlays.default ];

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
