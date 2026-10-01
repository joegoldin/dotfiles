# Atuin shell history, synced against the self-hosted server, plus Atuin AI
# (`?` on an empty prompt) against the self-hosted AI server on siofra
# (modules/hosts/siofra/atuin-ai.nix). Its own aspect (not part of fish)
# because it also integrates with bash and owns the agenix key wiring; rides on
# the joe user aspect like fish does.
{ inputs, ... }:
let
  domains = import "${inputs.dotfiles-secrets}/domains.nix";
in
{
  den.aspects.atuin.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # The AI server rejects requests without its bearer token. atuin reads
      # any setting from ATUIN_<SECTION>__<KEY>, so inject ai.api_token from
      # agenix at launch rather than writing it into the store-backed
      # config.toml. Hosts without the secret just get 401s from `?`.
      atuinWithAiToken = pkgs.symlinkJoin {
        # home-manager gates options on .version and runs lib.getExe on it.
        pname = "atuin";
        inherit (pkgs.unstable.atuin) version;
        meta.mainProgram = "atuin";
        paths = [ pkgs.unstable.atuin ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/atuin \
            --run 'if [ -r /run/agenix/atuin_ai_api_token ]; then export ATUIN_AI__API_TOKEN="$(cat /run/agenix/atuin_ai_api_token)"; fi'
        '';
      };
    in
    {
      programs.atuin = {
        enable = true;
        # unstable for self-hosted AI support (ai.endpoint_protocol, 18.20+).
        package = atuinWithAiToken;
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
          ai = {
            enabled = true;
            endpoint = "https://${domains.atuinAiDomain}";
            # "auto" would infer this from a non-Hub address too; explicit so a
            # misconfigured endpoint never falls back to the Hub login flow.
            endpoint_protocol = "oss";
          };
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

      # Atuin AI's /model writes the chosen model back into config.toml, which
      # fails on a read-only store symlink. Install a real copy instead; each
      # switch overwrites on-disk edits with the in-tree settings.
      xdg.configFile."atuin/config.toml".enable = lib.mkForce false;
      home.activation.atuinConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        mkdir -p ${config.xdg.configHome}/atuin
        rm -f ${config.xdg.configHome}/atuin/config.toml
        install -m644 ${
          (pkgs.formats.toml { }).generate "atuin-config" config.programs.atuin.settings
        } ${config.xdg.configHome}/atuin/config.toml
      '';
    };
}
