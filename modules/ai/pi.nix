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

      # The `!op read` fallback only works with the jail off, which means
      # torrent, where bubblewrap does not exist anyway. `op` needs the
      # desktop app's socket and biometric unlock, neither of which is bound
      # into the jail, and binding them would hand the agent the whole vault.
      #
      # So it is written on darwin only. It is not inert on linux: an explicit
      # providers.<name>.apiKey in models.json outranks the agenix environment
      # variables below, so shipping it there does not add a fallback, it
      # replaces a working key path with one that cannot succeed. Observed on
      # the activated system as "Failed to resolve API key for provider
      # anthropic from shell command: op read ...".
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
          providers = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
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

        # The statusline options come from agent-statusline's shared schema,
        # which claude-nix mounts under `statusLine` and pi-nix mounts here.
        # Everything else is left alone so both agents render from the same
        # defaults and the two lines stay identical by construction rather
        # than by a duplicated widget list.
        #
        # barWidth is the one exception, and the schema asks for it in so many
        # words: the shared default is 10, tracking the Go binary's
        # config.Defaults(), and claude-nix pins 8 for itself rather than
        # moving that default and breaking agent-statusline's Nix/Go drift
        # check. Its option doc names the consumer that wants the narrower bar
        # as the place to say so, which is here. An eval check renders both
        # option sets through the same renderConfig and asserts equality, so
        # this cannot drift silently.
        #
        # Under pi the `cost` widget always shows (the auth is
        # Codex/OpenRouter, so cost is the primary meter) and usage5h/usage7d
        # hide themselves for want of anthropic-ratelimit headers. That is
        # mode-gated inside the Go binary, not a config difference.
        statusline = {
          enable = true;
          barWidth = 8;
        };

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

        # The classifier that reads the rules in modules/ai/auto-mode.nix.
        # agent-skills fans the four lists out to this option but leaves
        # `enable` alone, and it is a plain mkEnableOption, so without this
        # line the rules are declared and never consulted. Claude Code has a
        # native classifier; pi's is this extension, and this design dropped
        # plan mode, so it and the jail are most of what stands between the
        # agent and the working tree.
        #
        # `model` stays null, which classifies with the session's own model.
        # A fixed cheap model would be cheaper, but it would also pin the
        # guard to one provider's key, and the whole point of the auth
        # layering above is that any of the three may be the one that is live.
        #
        # The deterministic allow list resolves the hottest read-only commands
        # without a model call at all. Every entry is already covered by the
        # natural-language `allow` list, so this buys latency rather than
        # permission, and a prefix rule can never resolve a compound command:
        # `git status && rm -rf .` starts with `git status ` and still falls
        # through to the classifier.
        autoMode = {
          enable = true;
          deterministic.allow = [
            "Bash(ls:*)"
            "Bash(cat:*)"
            "Bash(head:*)"
            "Bash(tail:*)"
            "Bash(wc:*)"
            "Bash(stat:*)"
            "Bash(rg:*)"
            "Bash(fd:*)"
            "Bash(jq:*)"
            "Bash(git status:*)"
            "Bash(git diff:*)"
            "Bash(git log:*)"
            "Bash(git show:*)"
            "Bash(git rev-parse:*)"
            "Bash(nix eval:*)"
            "Bash(nix build:*)"
            "Bash(nix flake check:*)"
            "Bash(nix path-info:*)"
          ];
        };

        # Claude Code notifies from inside the binary; pi does not, which is
        # why pi-nix ships the pi-notify extension and why its jail default
        # already carries the dbus talk permission the notifier needs. Leaving
        # this off would make that permission the only trace of a feature
        # nothing uses. Style and notifier path both default per platform,
        # notify-send on linux and terminal-notifier on darwin, resolved to an
        # absolute store path so they survive inside the jail.
        notifications.enable = true;

        # Peer messaging between separately launched pi instances, which is
        # pi's missing ListAgents/SendMessage. Local unix socket, no relay, no
        # daemon, no network. There is no phone or cross-machine story here and
        # there is not meant to be: the package that offered one was rejected
        # on its security model, and the addendum records what that cost.
        #
        # inboundTrigger stays at the module default ("replies"): the broker
        # authenticates nobody, so an unsolicited message must not be able to
        # start a turn. Raising it to "always", which is upstream's own
        # default, is a deliberate per-host choice rather than a convenience.
        messaging = {
          enable = true;
          askTimeoutSeconds = 300;
          # ~/.agents/skills already carries the skill library; loading the
          # extension's bundled copy too would double-register it.
          installSkill = false;
        };

        # Dictation. `/voice` spawns `audiomemo record --stream`, draws a VU
        # meter and the live transcript below the input box, and pastes the
        # finished text into the editor. The same keypress writes
        # `{voice:{enabled,mode}}` into ~/.claude/settings.local.json, which is
        # the file agent-statusline's mic widget already reads, so the
        # indicator lights under pi and under Claude Code from one
        # implementation.
        #
        # Every decision about devices, backends, formats and secrets stays in
        # audiomemo, which is why this block is four lines rather than a second
        # copy of the recording config.
        voice = {
          enable = true;
          # The exact derivation whose closure the jail binds, so ffmpeg is
          # reachable in there. pkgs.audiomemo comes from the flake's own
          # overlay, so this is the same build the `record` on PATH is.
          audiomemo = pkgs.audiomemo;

          # `device` is deliberately left at null. Both hosts already set
          # `record.device = "mic"` in their audiomemo config, and --stream
          # implies --no-tui, which suppresses the interactive picker outright
          # (cmd/record.go: the picker runs only when neither -D nor headless
          # mode is in play). Naming the alias here would duplicate the host's
          # device choice in a second file for no robustness: `-D mic` resolves
          # through the same config.toml that `record.device` lives in, so if
          # that file is missing both paths fail together.

          # Paths, never values. audiomemo opens each file itself, so no key
          # reaches the store or pi's process environment, and each path is
          # bound read-only into the jail. Mistral and HuggingFace are absent
          # because no such secret exists in dotfiles-secrets; audiomemo reads
          # an unset variable as an unconfigured backend, which is the right
          # answer rather than a degraded one.
          keyFiles = {
            ELEVENLABS_API_KEY_FILE = ageKey "elevenlabs_api_key";
            DEEPGRAM_API_KEY_FILE = ageKey "deepgram_api_key";
            OPENAI_API_KEY_FILE = ageKey "openai_api_key";
          };

          # The real file, not a store path: audiomemo's home-manager module
          # installs config.toml as a writable copy because the device TUI
          # edits it. Without this bind, jail.nix's tmpfs over $HOME hides it,
          # `record` decides it needs onboarding, and it dies opening /dev/tty.
          configFile = "${homeDir}/.config/audiomemo/config.toml";
        };

        # pi-background-tasks ships two extensions: the background bash this
        # host wants, and an Anthropic attribution gate that throws unless the
        # Anthropic credential is a subscription OAuth token. The keys here are
        # agenix API keys, so loading both stops pi from starting at all,
        # including `pi auth check`.
        #
        # Naming the entrypoint is narrower than the alternatives: dropping the
        # package would cost background bash, and moving Anthropic to OAuth
        # would be letting one extension choose this machine's auth.
        entrypointOverrides = {
          pi-background-tasks = [ "./extensions/background-tasks.ts" ];
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
        #
        # The microphone arrives the same way. pi-nix splices
        # `voice.jailPermissions` into its own default, so the PulseAudio and
        # PipeWire sockets, the audiomemo closure, config.toml and the three
        # key files above are all bound already. Adding them here would bind
        # them twice. `voice.jailPermissions` is exposed for a consumer who
        # replaces the permission list outright rather than merging into it,
        # which this file does not do.
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
