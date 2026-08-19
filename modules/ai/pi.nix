# pi (pi-nix) + the agent-skills library. The fourth first-class agent
# alongside Claude Code, Codex, and Antigravity.
#
# First run, once per machine:
#
#   pi
#   /login            # pick "ChatGPT Plus/Pro (Codex)" -> browser PKCE flow
#   /login openrouter # pick "Sign in with OpenRouter" -> mints a scoped key
#
# Both write ~/.pi/agent/auth.json (0600), which outranks the agenix
# environment variables, so the subscription paths win once they exist. Over
# SSH the loopback callback cannot be reached; paste the final redirect URL
# into the prompt instead. `/logout` clears a provider and drops it back to
# the agenix key.
{ inputs, ... }:
let
  # `op://` references for the models.json fallback keys. References, not
  # secrets; the real vault coordinates are private, so they come from the
  # secrets repo the same way day-sync's config does.
  piSecrets = import "${inputs.dotfiles-secrets}/pi.nix";
in
{
  den.aspects.pi.homeManager =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      # The same guard the sibling AI aspects use. pi's package comes from
      # pi-nix (re-exported through agent-skills) rather than the llm-agents
      # overlay, so this is not a hard dependency; it is this repo's marker
      # for "this host carries the AI toolchain", and keeping the condition
      # identical means all four agents switch on and off together.
      enabled = pkgs ? llm-agents;

      # jail.nix is bubblewrap, so linux only. pi-nix throws outright rather
      # than degrading if the flag is set on darwin, and torrent gets this
      # aspect.
      jailed = pkgs.stdenv.hostPlatform.isLinux;

      homeDir = config.home.homeDirectory;

      # agenix decrypts to /run/agenix/<name> on NixOS and on nix-darwin
      # alike, so one helper covers both. These are runtime paths handed to
      # pi as *strings*: pi-nix's `file` tag accepts `either str path`, and a
      # Nix path literal would copy the plaintext into the store.
      ageKey = name: "/run/agenix/${name}";

      # Last-resort provider keys, for a machine where agenix has not run.
      # This file holds only the *command* that fetches a key, never a key,
      # so it is safe in the store, but it is installed as a real 0600 file
      # rather than symlinked, because the jail binds only the runtime
      # closure and a bare store symlink would dangle inside it. Upstream's
      # own `models` option is deliberately unused: its prelude installs the
      # file only when absent, so a declared models.json goes stale on the
      # first edit.
      modelsJson = pkgs.writeText "pi-models.json" (
        builtins.toJSON {
          providers = {
            anthropic.apiKey = "!op read '${piSecrets.anthropicKeyRef}'";
            openai.apiKey = "!op read '${piSecrets.openaiKeyRef}'";
            openrouter.apiKey = "!op read '${piSecrets.openrouterKeyRef}'";
          };
        }
      );
    in
    {
      imports = [ inputs.agent-skills.homeManagerModules.pi ];

      programs.pi.coding-agent = lib.mkIf enabled {
        enable = true;

        # Auth, layered to match pi's resolution order (auth.json > env >
        # models.json). Nothing here fights the interactive `/login` flows:
        #
        #   1. `/login` (ChatGPT Plus/Pro for Codex, and OpenRouter's PKCE
        #      flow) writes ~/.pi/agent/auth.json, which outranks everything
        #      below. That is the primary path and needs no declaration; see
        #      the first-run runbook at the top of this file.
        #   2. These agenix-backed variables are the API-key path. pi-nix
        #      cats each file at launch, so the plaintext exists only in the
        #      wrapper's process environment.
        #   3. models.json's `!op read` entries (below) are the fallback for
        #      a machine that has not activated agenix yet.
        environment = {
          ANTHROPIC_API_KEY.file = ageKey "anthropic_api_key";
          OPENAI_API_KEY.file = ageKey "openai_api_key";
          OPENROUTER_API_KEY.file = ageKey "openrouter_api_key";
        };

        jail.enable = jailed;
      };

      # models.json is read-only from pi's perspective (it reloads on
      # `/model`; pi writes settings.json and auth.json, not this), so
      # re-installing it on every activation costs nothing and keeps the
      # op:// references from drifting.
      home.activation.piModelsJson = lib.mkIf enabled (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p ${lib.escapeShellArg "${homeDir}/.pi/agent"}
          run install -m 0600 ${modelsJson} ${lib.escapeShellArg "${homeDir}/.pi/agent/models.json"}
        ''
      );
    };
}
