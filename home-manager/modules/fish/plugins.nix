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
      name = "sdkman-for-fish";
      src = sdkman-for-fish.src;
    } # reitzig/sdkman-for-fish
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
  ];
}
