# Atuin shell history, synced against the self-hosted server. Its own aspect
# (not part of fish) because it also integrates with bash and owns the agenix
# key wiring; rides on the joe user aspect like fish does.
{ inputs, ... }:
let
  domains = import "${inputs.dotfiles-secrets}/domains.nix";
in
{
  den.aspects.atuin.homeManager =
    { lib, ... }:
    {
      programs.atuin = {
        enable = true;
        enableFishIntegration = true;
        enableBashIntegration = true;
        settings = {
          auto_sync = true;
          sync_frequency = "5m";
          sync_address = "https://${domains.atuinDomain}";
          search_mode = "fuzzy";
          enter_accept = true;
          inline_height = 20;
          filter_mode = "session-preload";
          filter_mode_shell_up_key_binding = "session-preload";
          accept_with_backspace = true;
          accept_past_line_start = true;
          command_chaining = true;
        };
      };

      # Symlink atuin's encryption key from agenix so it stays in sync across hosts.
      # Skips on hosts that don't manage atuin_key via agenix.
      home.activation.linkAtuinKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        AGENIX_KEY=/run/agenix/atuin_key
        TARGET="$HOME/.local/share/atuin/key"
        if [ -e "$AGENIX_KEY" ]; then
          mkdir -p "$(dirname "$TARGET")"
          if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
            backup="$TARGET.pre-agenix-$(date +%s)"
            echo "Backing up existing atuin key to $backup"
            mv "$TARGET" "$backup"
          fi
          ln -sfn "$AGENIX_KEY" "$TARGET"
        fi
      '';
    };
}
