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

      # NOTE: the `!op read` fallback only works with the jail off, which
      # means torrent, where bubblewrap does not exist anyway. `op` needs the
      # desktop app's socket and biometric unlock, neither of which is bound
      # into the jail, and binding them would hand the agent the whole vault.
      # On the linux workstations agenix is therefore the working key path and
      # this file is a statement of intent plus a darwin fallback.
      #
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

        # The jail wraps pi-nix's launch wrapper, not just the pi binary, so
        # the `cat /run/agenix/...` in the environment prelude above runs
        # *inside* bubblewrap and needs the secret files bound. jail.nix binds
        # only the runtime closure's store paths (/nix/store is not mounted
        # whole), so nothing on the host is visible unless it is named here.
        #
        # This is `mkDefault`, deliberately. pi-nix ships its own permission
        # set at the same priority, and `types.functionTo (listOf ...)` merges
        # by applying every definition and concatenating the results, so two
        # mkDefaults compose into "pi-nix's list, then this one". A plain
        # definition would be priority 100 and would silently discard pi-nix's
        # network, mount-cwd, notifications, toolchain and SSH entries instead.
        # That also keeps pi-nix free to change the generic set without a
        # dotfiles edit, and it is why gh, openssh and the ~/.ssh paths are
        # absent below: they already arrive from there.
        jail.permissions = lib.mkIf jailed (
          lib.mkDefault (combinators: [
            # The provider keys from the host modules. try-readonly, not
            # readwrite: pi only ever cats them, and the -try suffix matters
            # because activation order means a fresh machine may not have them
            # yet, where a hard bind of a missing path aborts the launch.
            (combinators.try-readonly "/run/agenix/anthropic_api_key")
            (combinators.try-readonly "/run/agenix/openai_api_key")
            (combinators.try-readonly "/run/agenix/openrouter_api_key")

            # user.name/user.email and the commit-signing config; without it
            # every commit made in the jail is authored by nobody.
            (combinators.try-readonly (combinators.noescape "~/.gitconfig"))

            # The `pr` widget shells out to gh, which needs its own config for
            # the host token. gh itself is already on the jailed PATH.
            (combinators.try-readonly (combinators.noescape "~/.config/gh"))

            # agent-statusline keeps its git and transcript caches here and the
            # `hook` subcommand writes the tool-timing sidecar, so this one is
            # read-write.
            (combinators.try-readwrite (combinators.noescape "~/.cache/agent-statusline"))
          ])
        );
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
