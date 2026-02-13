{pkgs, ...}: {
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
      src = pkgs.fetchFromGitHub {
        owner = "joegoldin";
        repo = "fish-ai";
        rev = "4b39b8aa04341322d3f9a1c11a14ca5800b71d28";
        hash = "sha256-E3/uRDNwn3tlXaUBKCGdPaWh93QNxF3cjZxplzYAgIo=";
      };
    }
    {
      name = "z";
      src = z.src;
    } # jethrokuan/z
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
