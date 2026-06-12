# Steam Deck with Jovian NixOS. Lean, gaming-focused home; picks features
# individually instead of home-baseline. Aspect content lives in the sibling
# files (system.nix, jovian.nix, home.nix).
{ inputs, den, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.hosts.x86_64-linux.joe-steamdeck.users.${meta.username} = { };

  den.aspects.joe-steamdeck = {
    includes = [
      den.aspects.nix-settings
      den.aspects.attic
      den.aspects.attic-post-build-hook
      den.aspects.numtide-cache
      den.aspects.gaming
      # home features (projected onto users via the host-aspects battery)
      den.aspects.bin
      den.aspects.plasma
      den.aspects.default-apps
      den.aspects.zen
    ];

    nixos = {
      imports = [
        inputs.jovian-nixos.nixosModules.default
        inputs.nix-index-database.nixosModules.default
        inputs.agenix.nixosModules.default
        ./_hardware-configuration.nix
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
  };
}
