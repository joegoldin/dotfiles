{pkgs, ...}: {
  plugins = with pkgs.fishPlugins; [
    {
      name = "z";
      src = z.src;
    } # jethrokuan/z
    {
      name = "tide";
      src = tide.src;
    } # jorgebucaran/tide
    {
      name = "autopair";
      src = autopair.src;
    } # jorgebucaran/autopair
    {
      name = "puffer";
      src = puffer.src;
    } # nickeb96/puffer-fish
    {
      name = "colored-man-pages";
      src = colored-man-pages.src;
    } # decors/fish-colored-man
    {
      name = "sponge";
      src = sponge.src;
    } # meaningful-ooo/sponge
    {
      name = "foreign-env";
      src = foreign-env.src;
    } # oh-my-fish/plugin-foreign-env
    {
      name = "fzf";
      src = fzf.src;
    } # PatrickF1/fzf.fish
    {
      name = "grc";
      src = grc.src;
    } # garabik/grc/grc.fish
    {
      name = "nix.fish";
      src = pkgs.fetchFromGitHub {
        owner = "kidonng";
        repo = "nix.fish";
        rev = "ad57d970841ae4a24521b5b1a68121cf385ba71e";
        sha256 = "13x3bfif906nszf4mgsqxfshnjcn6qm4qw1gv7nw89wi4cdp9i8q";
      };
    }
  ];
}
