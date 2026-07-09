# Lightweight home-manager config for headless server
# Does NOT import ../../home/_hm (too large for VPS disk)
# Instead, imports only the modules a server needs
{ ... }:
{
  den.aspects.rennala.homeManager =
    {
      pkgs,
      ...
    }:
    {
      imports = [
      ];

      programs = {
        home-manager.enable = true;

        # direnv with automatic fish/bash hooking (the fish aspect no longer
        # hooks direnv manually).
        direnv.enable = true;

        fish.shellAbbrs.lzd = "lazydocker";
      };
      systemd.user.startServices = "sd-switch";

      home = {

        packages = with pkgs; [
          comma
          coreutils
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
