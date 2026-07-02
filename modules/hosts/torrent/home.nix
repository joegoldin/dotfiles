# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{ inputs, ... }:
let
  inherit (inputs) dotfiles-assets;
in
{
  den.aspects.torrent.homeManager =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      initConfigAdditions = ''
        eval $(/opt/homebrew/bin/brew shellenv)
        if test "$TERM_PROGRAM" = "iTerm.app"
          source ${pkgs.iterm2-terminal-integration}/bin/iterm2_shell_integration.fish
        end
        fish_add_path -a /Applications/Obsidian.app/Contents/MacOS

        # Point SSH_AUTH_SOCK at 1Password's SSH agent. macOS launchd exports a
        # default SSH_AUTH_SOCK into every shell; in fish that global shadows any
        # `set -U`, so set a global here to win and make agent-aware tools (e.g.
        # `ssh-add -l`) talk to 1Password (matches the IdentityAgent below).
        set -gx SSH_AUTH_SOCK "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      '';
      fonts = import ../../_data/fonts { inherit pkgs lib dotfiles-assets; };
    in
    {
      imports = [
        ./_packages
        ./_python.nix
        ./_ghostty.nix
      ];

      home.packages = [
        fonts.berkeley-mono-nerd-font
      ];

      home.sessionVariables = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };

      programs = {
        fish.interactiveShellInit = lib.strings.concatStrings [
          (import ../../home/fish/_init.nix { inherit pkgs config; }).interactiveShellInit
          initConfigAdditions
        ];

        git.settings.gpg.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";

        ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings = {
            "*" = {
              identityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
            };
          };
          extraConfig = lib.mkOrder 100 ''
            IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
          '';
        };
      };
    };
}
