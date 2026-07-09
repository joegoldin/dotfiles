# Lightweight home-manager config for the headless erdtree server.
# Does NOT import the full home (too large for a server); imports only the
# tools a server needs (mirrors rennala).
{ ... }:
{
  den.aspects.erdtree.homeManager =
    { pkgs, ... }:
    {
      programs = {
        home-manager.enable = true;

        # direnv with automatic fish/bash hooking (the fish aspect no longer
        # hooks direnv manually).
        direnv.enable = true;

        fish.shellAbbrs.lzd = "lazydocker";
      };
      systemd.user.startServices = "sd-switch";

      home.packages = with pkgs; [
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

      # lorri for nix-shell
      services.lorri.enable = true;
    };
}
