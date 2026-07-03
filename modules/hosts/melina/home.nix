# Lightweight home-manager config for the headless melina host.
# Does NOT import the full home; imports only the tools a server needs
# (mirrors rennala / siofra).
{ ... }:
{
  den.aspects.melina.homeManager =
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
