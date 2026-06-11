# Steam Deck with Jovian NixOS.
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.hosts.x86_64-linux.joe-steamdeck.users.${meta.username} = { };

  den.aspects.joe-steamdeck = {
    includes = [ den.aspects.hm-settings ];

    nixos = {
      imports = [
        inputs.jovian-nixos.nixosModules.default
        inputs.nix-index-database.nixosModules.default
        inputs.nix-attic-infra.nixosModules.attic-post-build-hook
        inputs.agenix.nixosModules.default
        ../../system/_sys/attic.nix
        ../../system/_sys/numtide-cache.nix
        ../../system/_sys/attic-post-build-hook.nix
        ../../system/_sys/gaming.nix
        ./_configuration.nix
        ./_hardware-configuration.nix
        ./_jovian.nix
      ];

      _module.args.hostname = "joe-steamdeck";

      home-manager.sharedModules = [
        inputs.plasma-manager.homeModules.plasma-manager
        inputs.nix-attic-infra.homeManagerModules.attic-client
      ];

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

    provides.to-users.homeManager = {
      imports = [ ./_home-manager.nix ];
    };
  };
}
