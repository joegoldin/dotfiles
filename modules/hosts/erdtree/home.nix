# Lightweight home-manager config for the headless erdtree server.
# Does NOT import the full home (too large for a server); imports only the
# tools a server needs (mirrors rennala).
{ ... }:
{
  den.aspects.erdtree.homeManager =
    { pkgs, ... }:
    {
      programs.home-manager.enable = true;
      systemd.user.startServices = "sd-switch";

      home.packages = with pkgs; [
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

      # lorri for nix-shell
      services.lorri.enable = true;
    };
}
