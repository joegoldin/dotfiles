# User aspect: everything "joe" carries to every den-managed host;
# the OS account (pushed to hosts via provides.to-hosts) and the universal
# home features. Per-host group additions live in each host's system file
# (list definitions merge); host-specific home features ride on the host
# aspect via the host-aspects battery.
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
      den.aspects.atuin
      den.aspects.gh
      den.aspects.gpg
      den.aspects.starship
    ];

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

    provides.to-hosts.darwin =
      { pkgs, ... }:
      {
        users.users.${meta.username} = {
          # home-manager's darwin module derives home.homeDirectory from this
          home = "/Users/${meta.username}";
          shell = pkgs.fish;
          openssh.authorizedKeys.keys = [ keys.${meta.username} ];
          description = meta.username;
        };
      };

    homeManager =
      { lib, pkgs, ... }:
      {
        programs.home-manager.enable = true;
        systemd.user.startServices = lib.mkDefault "sd-switch";

        home.username = lib.mkDefault meta.username;
        home.homeDirectory = lib.mkDefault (
          (if pkgs.stdenv.isDarwin then "/Users/" else "/home/") + meta.username
        );
      };
  };
}
