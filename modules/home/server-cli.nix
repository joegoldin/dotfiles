# Shared CLI kit for the lean headless servers (rennala, siofra, erdtree,
# melina). They skip home-baseline (too heavy for small VPSes); this aspect
# is the curated set they share instead. git/fish/gh/gpg/starship still ride
# on the joe user aspect. dectus keeps its own hand-rolled variant.
_: {
  den.aspects.server-cli.homeManager =
    { pkgs, ... }:
    {
      programs = {
        home-manager.enable = true;

        # direnv with automatic fish/bash hooking (the fish aspect doesn't
        # hook direnv manually).
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
