# Lightweight home-manager config for headless server
# Does NOT import ../../home/_hm (too large for VPS disk)
# Instead, imports only the modules a server needs
{ ... }:
let
  meta = import ../../_lib/meta.nix;
  stateVersion = "24.11";
  username = meta.username;
in
{
  den.aspects.racknerd-cloud-agent.homeManager =
    {
      pkgs,
      ...
    }:
    {
      imports = [
      ];

      programs.home-manager.enable = true;
      systemd.user.startServices = "sd-switch";

      home = {

        packages = with pkgs; [
          comma
          coreutils
          direnv
          dua
          file
          fish
          fzf
          gawk
          git
          gnumake
          gnupg
          gnused
          gnutar
          httpie
          jq
          lazydocker
          nix-output-monitor
          nix-your-shell
          nixfmt
          ripgrep
          tmux
          tree
          unstable.just
          unzip
          watch
          wget
          which
          yq-go
          zip
          zstd
        ];
      };

      # lorri for nix-shell
      services.lorri.enable = true;

    };
}
