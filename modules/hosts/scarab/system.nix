# Base system for crawler: ssh (key-only), passwordless sudo, timezone, shells,
# a small package set, and the lean inline home kit. Mirrors dectus /
# racknerd. Does NOT set nixpkgs.hostPlatform — nixos-raspberrypi's builder
# owns it. The shell *config* (fish/git/starship/gh/gpg) is not repeated here;
# it already arrives via the joe user aspect (modules/users/joe.nix).
{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
  keys = import "${inputs.dotfiles-secrets}/keys.nix";
in
{
  den.aspects.scarab = {
    nixos =
      { pkgs, ... }:
      {
        time.timeZone = "America/Los_Angeles";
        security.sudo.wheelNeedsPassword = false;

        users.users.root.openssh.authorizedKeys.keys = [ keys.${meta.username} ];

        programs = {
          fish.enable = true;
          zsh.enable = true;
        };

        environment.systemPackages = with pkgs; [
          git
          wget
        ];

        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
          };
        };
      };

    # Lean CLI kit projected onto joe via the host-aspects battery. fish/git/
    # starship/gh/gpg come from the joe user aspect; shell-tools (an include in
    # default.nix) adds direnv/skim. This list is just extra utilities.
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          ripgrep
          fd
          jq
          yq-go
          tree
          tmux
          fzf
          htop
          file
          unzip
          curl
          nix-output-monitor
          unstable.just
        ];
      };
  };
}
