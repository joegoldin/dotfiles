# User aspect: everything "joe" carries to every den-managed host.
# Host-specific extras come from each host's provides.to-users instead.
{ inputs, den, ... }:
let
  meta = import ../_lib/meta.nix;
  keys = import "${inputs.dotfiles-secrets}/keys.nix";
in
{
  den.aspects.${meta.username} = {
    includes = [
      den.aspects.git
      den.aspects.fish
      den.aspects.gh
      den.aspects.gpg
      den.aspects.starship
    ];

    # OS-level account (was users.users.joe in hosts/*/configuration.nix)
    provides.to-hosts.nixos =
      { pkgs, ... }:
      {
        users.users.${meta.username} = {
          uid = 1000;
          isNormalUser = true;
          shell = pkgs.fish;
          openssh.authorizedKeys.keys = [ keys.${meta.username} ];
          extraGroups = [
            "wheel"
            "networkmanager"
          ];
        };
      };

    homeManager =
      { lib, pkgs, ... }:
      {
        programs.home-manager.enable = true;
        systemd.user.startServices = "sd-switch";

        home.username = lib.mkDefault meta.username;
        home.homeDirectory = lib.mkDefault (
          (if pkgs.stdenv.isDarwin then "/Users/" else "/home/") + meta.username
        );
      };
  };
}
