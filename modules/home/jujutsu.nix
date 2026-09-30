{ ... }:
{
  den.aspects.jujutsu.homeManager =
    {
      config,
      pkgs,
      ...
    }:
    let
      # Matches ghostty's "Gruvbox Dark Hard"; jjui's default selection
      # colors are unreadable against it.
      jjuiTheme = "base16-gruvbox-dark-hard";
      jjuiThemeFile = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/vic/tinted-jjui/2b33e8f6213c343ad570a40e2d5e874e3fdb9541/themes/${jjuiTheme}.toml";
        hash = "sha256-r1WmNONruB3e9NyxjgMrqN2NNH+Ck6qU8cDuDGWDRuw=";
      };
    in
    {
      # Stack aliases and revsets; see the file header.
      xdg.configFile."jj/conf.d/stacks.toml".source = ./_jj-stacks.toml;

      home.packages = [ pkgs.unstable.stakk ];

      home.file."${config.programs.jjui.configDir}/themes/${jjuiTheme}.toml".source = jjuiThemeFile;

      # stakk settings go in the environment rather than its config file,
      # which lives outside XDG on macOS. github.com needs no host setting.
      home.sessionVariables = {
        # Register every stack with GitHub's native stacked PRs; submit
        # fails (after pushing and opening the PRs) on repos without them.
        STAKK_NATIVE_STACKS = "on";
        STAKK_PR_MODE = "draft";
      };

      programs = {
        # Page jj diffs through the same delta setup as git (./git.nix).
        delta.enableJujutsuIntegration = true;

        # jj on top of git: repos stay plain git remotes, colocated (jj's
        # default) so git tooling like gh and editors keeps working alongside.
        jujutsu = {
          enable = true;
          # _jj-stacks.toml targets jj 0.43+; stable still ships 0.41.
          package = pkgs.unstable.jujutsu;

          settings.user = {
            name = "Joe Goldin";
            email = "joe@joegold.in";
          };
        };

        # TUI for jj; from unstable to track the jj it drives.
        jjui = {
          enable = true;
          package = pkgs.unstable.jjui;
          settings.ui.theme = jjuiTheme;
        };
      };
    };
}
