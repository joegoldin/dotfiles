# Oracle Cloud bastion (pelican game servers + tailnet entry).
# Entity name (= flake output) is oracle-cloud-bastion; the machine's
# hostName is "bastion". Host-specific modules live alongside as _-files
# (invisible to import-tree). Module args (username, keys, …) come from the
# shim in modules/nix/module-args.nix; `hostname` is set here.
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
    includes = [ den.aspects.hm-settings ];

    nixos = {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.nix-index-database.nixosModules.default
        inputs.pelican.nixosModules.default
        inputs.agenix.nixosModules.default
        ../../system/_sys/attic.nix
        ../../system/_sys/numtide-cache.nix
        ./_configuration.nix
        ./_disk-config.nix
        ./_hardware-configuration.nix
        ./_oracle-cloud.nix
        ./_pelican.nix
      ];

      _module.args.hostname = "bastion";

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

    provides.to-users.homeManager = {
      imports = [
        ./_home-manager.nix
        # flake-input hm modules (were imports in modules/home/_hm/default.nix)
        inputs.audiomemo.homeManagerModules.default
        inputs.nix-attic-infra.homeManagerModules.attic-client
        inputs.agent-skills.homeManagerModules.claude
        inputs.agent-skills.homeManagerModules.antigravity
        inputs.agent-skills.homeManagerModules.codex
        inputs.agent-skills.homeManagerModules.agent-skills
      ];
    };
  };
}
