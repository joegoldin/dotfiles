{ pkgs, fishAiSrc, ... }:
let
  # Upstream nix.fish appends ~/.nix-defexpr/channels to $NIX_PATH unconditionally,
  # which produces a warning on every nix invocation when channels are disabled.
  # Guard the append with `test -e` so it only fires when the path actually exists.
  nixFishSrc = pkgs.runCommand "nix.fish-src" { } ''
    cp -r ${
      pkgs.fetchFromGitHub {
        owner = "kidonng";
        repo = "nix.fish";
        rev = "ad57d970841ae4a24521b5b1a68121cf385ba71e";
        sha256 = "13x3bfif906nszf4mgsqxfshnjcn6qm4qw1gv7nw89wi4cdp9i8q";
      }
    } $out
    chmod -R +w $out
    substituteInPlace $out/conf.d/nix.fish \
      --replace-fail \
        'contains $channels $NIX_PATH || set --global --export --append NIX_PATH $channels' \
        'test -e $channels; and not contains $channels $NIX_PATH; and set --global --export --append NIX_PATH $channels'
  '';

  # grc.fish echoes "You need to install grc!" to stdout whenever `grc` isn't on
  # PATH — unguarded, so it fires on NON-interactive shells too (e.g. `ssh host
  # 'cat'`), which corrupts scp/sftp/rsync streams. Guard the warning so it only
  # prints in interactive shells.
  grcSrc = pkgs.runCommand "grc.fish-src" { } ''
    cp -r ${pkgs.fishPlugins.grc.src} $out
    chmod -R +w $out
    substituteInPlace $out/conf.d/grc.fish \
      --replace-fail \
        "echo 'You need to install grc!'" \
        "status is-interactive; and echo 'You need to install grc!'"
  '';
in
{
  plugins = with pkgs.fishPlugins; [
    # Refresh prompt on command - shows accurate time/git status at execution time
    {
      name = "fish-refresh-prompt-on-cmd";
      src = pkgs.fetchFromGitHub {
        owner = "infused-kim";
        repo = "fish-refresh-prompt-on-cmd";
        rev = "8f01915193ea6ad3b3339f70554732bc392a6465";
        sha256 = "0v348ysx0xrdh09shvly50mlmdlmx7bjgd4476p6wj2cvbxdfiyb";
      };
    }
    {
      name = "fish-ai";
      src = fishAiSrc;
    }
    {
      name = "z";
      inherit (z) src;
    } # jethrokuan/z
    {
      name = "colored-man-pages";
      inherit (colored-man-pages) src;
    } # decors/fish-colored-man
    {
      name = "sponge";
      inherit (sponge) src;
    } # meaningful-ooo/sponge
    {
      name = "foreign-env";
      inherit (foreign-env) src;
    } # oh-my-fish/plugin-foreign-env
    {
      name = "fzf";
      inherit (fzf) src;
    } # PatrickF1/fzf.fish
    {
      name = "grc";
      src = grcSrc;
    } # garabik/grc/grc.fish (warning guarded to interactive shells)
    {
      name = "nix.fish";
      src = nixFishSrc;
    }
  ];
}
