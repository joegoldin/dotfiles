# User aspect: everything "joe" carries to every den-managed host.
# Host-specific extras come from each host's provides.to-users / legacy tree.
#
# Every value is mkDefault'd: the per-host _configuration.nix files under
# modules/hosts/*/ still define users.users.joe themselves, and those plain
# definitions must keep winning. On hosts where nothing else defines the
# user (cloud-proxy) the defaults below are the definition.
#
# The included feature aspects dedup against the per-host home trees: every
# modules/hosts/*/_home-manager.nix imports these same files, and the module
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

    # OS-level account (hosts' _configuration.nix definitions override these)
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
