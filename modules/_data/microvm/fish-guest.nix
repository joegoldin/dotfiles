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
in
{
  imports = [ ../../home/bin/_module.nix ];

  # Tell `./bin` to strip hostOnly scripts for guest use.
  _module.args.vmGuest = true;

  # home-manager requires an explicit stateVersion; username/homeDirectory
  # are inferred from the NixOS user config (useUserPackages = true).
  home.stateVersion = "25.11";

  programs.fish = {
    enable = true;

    functions = import ../../home/fish/_functions.nix;
    inherit ((import ../../home/fish/_aliases.nix { inherit lib pkgs config; }))
      shellAbbrs
      shellAliases
      ;

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
        src = nixFishSrc;
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
