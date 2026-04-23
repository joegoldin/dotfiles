# Minimal fish configuration for microVM guests. Imports into `common-guest.nix`.
#
# Deliberately excludes:
#   - fish-ai (needs ANTHROPIC_API_KEY via agenix, not available in guest)
#   - atuin (needs sync server / host keys)
#   - host-specific init (playwright, nvm, npm-global PATH — irrelevant in a VM)
# Includes:
#   - fish itself + functions + aliases/abbrs (shared with host config)
#   - a curated subset of plugins (z, colored-man-pages, sponge, fzf, nix.fish)
#   - starship prompt
#   - repo bin scripts with `vmGuest = true;` so `hostOnly` ones are stripped
{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [ ./bin ];

  # Tell `./bin` to strip hostOnly scripts for guest use.
  _module.args.vmGuest = true;

  # home-manager requires an explicit stateVersion; username/homeDirectory
  # are inferred from the NixOS user config (useUserPackages = true).
  home.stateVersion = "25.11";

  programs.fish = {
    enable = true;

    functions = import ./fish/functions.nix;
    inherit ((import ./fish/aliases.nix { inherit lib config; })) shellAbbrs shellAliases;

    plugins = with pkgs.fishPlugins; [
      {
        name = "z";
        inherit (z) src;
      }
      {
        name = "colored-man-pages";
        inherit (colored-man-pages) src;
      }
      {
        name = "sponge";
        inherit (sponge) src;
      }
      {
        name = "fzf";
        inherit (fzf) src;
      }
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

    interactiveShellInit = ''
      set -Ux Z_CMD "j"
      fish_add_path $HOME/.local/bin
    '';
  };

  programs.starship.enable = true;

  # Core CLI the user expects regardless of profile.
  home.packages = with pkgs; [
    fish
    starship
    git
    curl
    wget
    ripgrep
    fd
    jq
    htop
    tmux
    fzf
  ];
}
