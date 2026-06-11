# User aspect: everything "joe" carries to every den-managed host.
# Host-specific extras come from each host's provides.to-users / legacy tree.
#
# Every value is mkDefault'd: the not-yet-extracted host trees under hosts/
# still define users.users.joe themselves, and those plain definitions must
# keep winning until they migrate. On hosts where nothing else defines the
# user (cloud-proxy) the defaults below are the definition.
#
# The included feature aspects dedup against the legacy hm trees: every
# hosts/*/home-manager.nix already imports these same files, and the module
# system deduplicates imports by path.
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
      { lib, pkgs, ... }:
      {
        users.users.${meta.username} = {
          uid = lib.mkDefault 1000;
          isNormalUser = lib.mkDefault true;
          shell = lib.mkDefault pkgs.fish;
          openssh.authorizedKeys.keys = lib.mkDefault [ keys.${meta.username} ];
          extraGroups = lib.mkDefault [
            "wheel"
            "networkmanager"
          ];
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
