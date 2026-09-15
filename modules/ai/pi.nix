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

      # pi-nix's own package set, reached through agent-skills rather than
      # added as a second input, so there is one place that decides which
      # pi-nix this machine runs.
      piPkgs = inputs.agent-skills.inputs.pi-nix.packages.${pkgs.stdenv.hostPlatform.system};

      homeDir = config.home.homeDirectory;

      # agenix decrypts to /run/agenix/<name> on NixOS and on nix-darwin
      # alike, so one helper covers both. These are runtime paths handed to
      # pi as *strings*: pi-nix's `file` tag accepts `either str path`, and a
      # Nix path literal would copy the plaintext into the store.
      ageKey = name: "/run/agenix/${name}";

      # The `!op read` fallback is written on darwin only, where the desktop
      # app's biometric unlock is the working key path. It is not inert on
      # linux: an explicit
      # providers.<name>.apiKey in models.json outranks the agenix environment
      # variables below, so shipping it there does not add a fallback, it
      # replaces a working key path with one that cannot succeed. Observed on
      # the activated system as "Failed to resolve API key for provider
      # anthropic from shell command: op read ...".
      #
      # Last-resort provider keys, for a machine where agenix has not run.
      # This file holds only the *command* that fetches a key, never a key,
      # so it is safe in the store. It is installed by the activation step at
      # the bottom of this file rather than as a store symlink. Upstream's
      # own `models` option is deliberately unused: its prelude installs the
      # file only when absent, so a declared models.json goes stale on the
      # first edit.
      # Standard Compute is an OpenAI-compatible gateway: one endpoint, one
      # model id, and a router that picks the actual model per request. Billing
      # is per account rather than per token, which is why every cost figure is
      # zero — pi multiplies usage by these, so leaving them out would make the
      # statusline invent a number.
      #
      # `api` is openai-responses because that is what their own integration
      # guide specifies, and the endpoint table lists /v1/responses alongside
      # /v1/completions. The key is `$VAR`, not a literal: pi interpolates it
      # at read time from the environment exported above, so this file stays
      # safe in the store.
      standardComputeProvider = {
        standardcompute = {
          name = "Standard Compute";
          baseUrl = "https://api.stdcmpt.com/v1";
          apiKey = "$STANDARDCOMPUTE_API_KEY";
          api = "openai-responses";
          models = [
            {
              id = "standardcompute";
              name = "Standard Compute";
              reasoning = false;
              input = [
                "text"
                "image"
              ];
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
              contextWindow = 200000;
              maxTokens = 8192;
            }
          ];
        };
      };

      modelsJson = pkgs.writeText "pi-models.json" (
        builtins.toJSON {
          providers =
            standardComputeProvider
            // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
              anthropic.apiKey = "!op read '${piSecrets.anthropicKeyRef}'";
              openai.apiKey = "!op read '${piSecrets.openaiKeyRef}'";
              openrouter.apiKey = "!op read '${piSecrets.openrouterKeyRef}'";
            };
        }
      );
    in
    {
      imports = [ inputs.agent-skills.homeManagerModules.pi ];

      # Per-provider launchers. Functions rather than abbreviations, because an
      # abbreviation expands the moment you type its name, before any argument
      # exists, so it cannot forward one.
      #
      # Each takes an optional model as its first argument and passes the rest
      # to pi untouched, so `pi-openrouter deepseek/deepseek-r1 --print "hi"`
      # does what it looks like. With no argument they use the provider's
      # default.
      programs.fish.functions = lib.mkIf enabled {
        pi-codex = {
          description = "pi on the Codex subscription (default: gpt-5.6-sol:xhigh)";
          body = ''
            if set -q argv[1]
                command pi --model openai-codex/$argv[1] $argv[2..]
            else
                command pi --model openai-codex/gpt-5.6-sol:xhigh $argv
            end
          '';
        };

        pi-openrouter = {
          description = "pi on OpenRouter (first argument is the model)";
          body = ''
            if set -q argv[1]
                command pi --model openrouter/$argv[1] $argv[2..]
            else
                echo "pi-openrouter: name a model, e.g. anthropic/claude-sonnet-4" >&2
                echo "browse them with: pi --list-models openrouter" >&2
                return 1
            end
          '';
        };

        # One model id; their gateway routes per request, so there is nothing
        # to choose and an argument here would only be a prompt.
        pi-standardcompute = {
          description = "pi on Standard Compute";
          body = "command pi --model standardcompute/standardcompute $argv";
        };

        pi-sc = {
          description = "Alias for pi-standardcompute";
          body = "pi-standardcompute $argv";
        };
      };

      programs.pi.coding-agent = lib.mkIf enabled {
        enable = true;

        # agent-skills picks the curated set and hands it over with mkDefault.
        # @gotgenes/pi-permission-system is back on it. It was dropped because
        # both packages gate `tool_call` and pi returns on the first extension
        # that blocks, so the permission system answered every ask and the
        # classifier was never consulted — including for `git status --short
        # --branch`, which the allow list names.
        #
        # Ordering was never the fix. The permission system publishes a chain
        # seam for exactly this, and pi-nix now builds a fork of pi-automode
        # that registers on it, so the classifier answers the asks the
        # deterministic engine cannot settle and the two layers compose.
        # `autoMode.permissionSystem` below arms it.
        extensionPackages = map (n: piPkgs.${n}) [
          "ext-gotgenes-pi-permission-system"
          "ext-pi-mcp-adapter"
          "ext-pi-subagents"
          "ext-pi-background-tasks"
          "ext-juicesharp-rpiv-ask-user-question"
          "ext-juicesharp-rpiv-todo"
          "ext-narumitw-pi-goal"
          "ext-narumitw-pi-btw"
          "ext-pi-cache-optimizer"
          "ext-heyhuynhgiabuu-pi-pretty"
        ];

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
        # Three providers, three mechanisms, deliberately.
        #
        # OpenAI is reached through the Codex subscription and `/login` only,
        # so no OPENAI_API_KEY appears here. An API key would silently outrank
        # nothing — auth.json wins — but it would still let a stray `--provider
        # openai` bill a metered key when the subscription was the point.
        # Note this is not the same variable as the OPENAI_API_KEY_FILE further
        # down: that one is audiomemo's transcription key, a different service
        # on the same vendor, and it stays.
        #
        # Anthropic is absent for the same reason: nothing here is meant to
        # reach it, and a key sitting in the environment is a provider you did
        # not choose.
        environment = {
          # Not a settings key. Separate from enableInstallTelemetry, and
          # pointless here either way: the version is whatever the flake
          # pinned, so a newer one upstream is not something pi can act on.
          PI_SKIP_VERSION_CHECK.value = "1";

          # Auto mode draws its own status slot unless told not to, and this
          # setup already has a status line. Suppressed here, the fork
          # republishes the same tally on the `pi-automode:status` channel and
          # agent-statusline renders it as its own row, so the numbers are
          # unchanged and drawn once rather than twice.
          PI_AUTOMODE_NO_STATUS_SLOT.value = "1";

          # The same thing again, for pi-cache-optimizer. It writes
          # `OpenAI cache 77/79·5.40M/5.75M 93.9%` into a slot of its own with
          # no setting to stop it, so pi-nix patches the call to honour this.
          # No republication needed, unlike auto mode: the figures are already
          # on disk in pi-cache-optimizer-stats.json, which is where the `cache`
          # widget reads them from and why it can draw them in this theme with
          # this bar rather than in the extension's own format.
          PI_CACHE_OPTIMIZER_NO_STATUS_SLOT.value = "1";

          OPENROUTER_API_KEY.file = ageKey "openrouter_api_key";
          # Standard Compute: one key, one model id, their router picks the
          # model per request. Referenced by name from the provider entry
          # below rather than inlined, so the key stays out of the store.
          STANDARDCOMPUTE_API_KEY.file = ageKey "standardcompute_api_key";
        };

        # The guardrail that reads the rules in modules/ai/auto-mode.nix.
        # agent-skills fans the four lists out to this option but leaves
        # `enable` alone, and it is a plain mkEnableOption, so without this
        # line the rules are declared and never consulted. Claude Code has a
        # native classifier; pi's is @czottmann/pi-automode. This design
        # dropped plan mode and pi runs unsandboxed, so it is most of what
        # stands between the agent and the machine.
        #
        # It is on from the first turn rather than after a slash command: the
        # rendered config sets `enabled` and reaches the extension as
        # PI_AUTOMODE_SETTINGS_JSON, which outranks both config files, so a
        # leftover ~/.pi/agent/automode.json cannot quietly turn it off.
        autoMode = {
          enable = true;

          # A small fast model, not the session's. Classification runs on
          # every side-effecting tool call, and null bills that at the session
          # model's rate, which for gpt-5.6-sol:xhigh is a poor trade for a
          # yes/no. luna is the cheap tier of the same Codex subscription the
          # session already authenticates against, so this adds no second key
          # to keep alive.
          classifierModel = "openai-codex/gpt-5.6-luna";

          # Reads inside the working tree resolve with no model call, and
          # reads outside it are classified rather than waved through. The
          # working tree is the one place the user has already put in front
          # of the agent; everywhere else is reviewed. Writes to protected
          # in-tree paths (.git, .pi, shell profiles) are carved back out and
          # still classified.
          allowInsideWorkingDirectory = true;

          # Secrets the file tools must never open, matched before any
          # classifier call and against the symlink-resolved path as well as
          # the one written. These restate hard_deny rules from
          # auto-mode.nix that a model would otherwise be the only thing
          # enforcing. bash access to the same paths stays the classifier's
          # problem; this list governs read/write/edit/grep/find/ls.
          deniedPaths = [
            "~/.ssh/*"
            "/run/agenix/*"
            "~/.aws/*"
            "~/.config/op/*"
            "~/.pi/agent/auth.json"
            "~/.claude/.credentials.json"
            "*.env"
          ];

          # No protectedPaths. The package ships 48 by default, all of them
          # files where a write causes code to run later, and they are dropped
          # deliberately rather than overlooked.
          #
          # The hard_deny list already names that class in words the classifier
          # reads — cron, systemd user timers, git hooks, .envrc, shell
          # profiles — so the gate was a second copy of a rule that already
          # exists. What goes with it is the long tail the prose does not name:
          # .mcp.json, .pnpmfile.cjs, the Gradle and Maven wrappers, the
          # pre-commit and lefthook configs. Those now rest on the classifier
          # recognising a config edit as a persistence mechanism, which is a
          # real bet rather than a free one.
          #
          # The trade is deliberate: fewer moving parts, one place where policy
          # lives, and no deterministic list to drift out of date. Revisit if a
          # write to one of those files ever gets through.
          #
          # `[ ]` here is a value, not an omission. The extension keeps its
          # built-ins for any section it never sees, so leaving the option
          # unset would restore all 48 rather than clear them.
          protectedPaths = [ ];

          # Deterministic, no model call, and unlike the natural-language
          # lists these cannot be reasoned with.
          # A bash pattern is matched against the whole command string with
          # `*` spanning anything, so these catch a credential path wherever
          # it appears in the line. deniedPaths cannot: it governs the file
          # tools only, and `cat` is bash. Obfuscation gets past this (a
          # variable, a glob, base64), so it is a net rather than a boundary
          # — the boundary is the classifier, which reads the hard_deny rule
          # in plain words, and whatever sandbox the user launched pi inside.
          permissions.deny = [
            "bash(*/run/agenix/*)"
            "bash(*/.ssh/id_*)"
            "bash(*/agent/auth.json*)"
            "bash(*/.credentials.json*)"
            "write(*.env)"
            "edit(*.env)"
          ];

          # The decision log is the only way to answer "why was that
          # blocked" after the fact. classifierIo stays off: it would write
          # the transcript evidence to disk on every classified call.
          log.enable = true;

          # The half that arms the chain link. pi-nix renders this whole
          # attrset to
          # ~/.pi/agent/extensions/pi-permission-system/config.json and the
          # launcher installs it on every start, so it replaces the file
          # rather than merging into it: anything not named here is gone, and
          # `authorizerChain` is appended by pi-nix.
          #
          # The three package defaults are kept as they were on disk.
          # permissionReviewLog earns its place twice over now: it is the only
          # record that a decision came from the chain link rather than from a
          # dialog, which is the difference this arrangement exists to make.
          permissionSystem.settings = {
            debugLog = false;
            permissionReviewLog = true;
            yoloMode = false;

            # Everything not named here falls back to the package's own `ask`,
            # which under this arrangement means "hand it to the classifier"
            # rather than "prompt". That is the intended shape: the permission
            # system resolves what a flat rule can resolve, auto mode's 63
            # natural-language rules resolve the rest, and neither one has to
            # restate the other.
            #
            # external_directory is the exception, and it is not a preference.
            # The chain owner caps a link's `allow` on the `external_directory`
            # and `path` surfaces and turns it into a `defer`
            # (src/authority/delegation-envelope.ts), so on those two surfaces
            # the classifier can refuse but cannot approve, and an approval
            # falls through to a dialog. Measured, not assumed: reading
            # /etc/hostname from a session rooted elsewhere raised an
            # `external_directory` ask, the link answered allow, and the
            # decision came back
            # `{"kind":"unavailable"}` under --print.
            #
            # Only the store is named. It is immutable and every nix command
            # reads it, so a prompt there asks about something that cannot
            # change. ~/Development and ~/dotfiles were listed here once and
            # are deliberately not: a session rooted in one repository reaching
            # into another is exactly the case worth seeing, and the working
            # directory is already allowed by allowInsideWorkingDirectory.
            # Anything else outside the working directory still reaches a
            # prompt, which is the right answer for a path nobody described.
            #
            # Each directory is named twice, bare and with a trailing `*`,
            # because those are two different patterns and not a shorthand for
            # each other. The extension's own schema doc puts it plainly: "the
            # trailing `*` is greedy and crosses subdirectory boundaries; a
            # bare `~/.cargo/registry` matches only the directory entry
            # itself." So `/nix/store/*` covers every path under the store and
            # nothing else, and `find /nix/store -path ...` -- whose external
            # directory is the store itself -- fell through to `*` and asked.
            # Observed as a live prompt, not inferred.
            permission = {
              external_directory = {
                "*" = "ask";
                "/nix/store" = "allow";
                "/nix/store/*" = "allow";
              };

              # The `path` surface, which is a different thing from the rules
              # above and not a second copy of them. It is cross-cutting -- pi's
              # own file tools, bash path tokens, MCP arguments and extension
              # tools all pass through it -- and a deny here cannot be overridden
              # by a per-tool allow. It is also inside the delegation envelope,
              # so the classifier can refuse on it and can never approve.
              #
              # Which is why these three are named here rather than on
              # external_directory: they are the credential material pi's own
              # launcher and login flow put on this machine, and with no sandbox
              # around the process this rule is what keeps a tool call away from
              # them. Three entries, not a policy: everything else still reaches
              # the classifier.
              #
              #   /run/agenix/*        the provider keys the launcher cats.
              #   /proc/*/environ      the same keys again, and the Codex OAuth
              #                        token, via any process's environment.
              #   ~/.pi/agent/auth.json  the `/login` tokens.
              #
              # Not airtight, and worth saying so rather than implying otherwise:
              # `printenv` reads the same variables out of the process it already
              # runs in, and no path rule reaches that. What these stop is the
              # file being read, copied, or sent somewhere by a tool call.
              path = {
                "/run/agenix/*" = "deny";
                "/proc/*/environ" = "deny";
                "${homeDir}/.pi/agent/auth.json" = "deny";
              };
            };
          };
        };

        # Claude Code notifies from inside the binary; pi does not, which is
        # why pi-nix ships the pi-notify extension. Style and notifier path
        # both default per platform, notify-send on linux and
        # terminal-notifier on darwin, resolved to an absolute store path.
        notifications = {
          enable = true;

          # A notification is worth an interrupt only when the session cannot
          # continue without the user: a permission prompt, or the turn ending
          # and control coming back. `long_running_tool` is neither. It reports
          # progress on work that is proceeding fine, and at a 30 s threshold on
          # a machine whose common tools are nix builds and flake checks it
          # fires on most of them, which trains the notification to be ignored.
          events = [
            "needs_input"
            "settled"
          ];
        };

        # Claude Code skills that live in a repository rather than in the
        # shared library. pi's skill roots are ~/.pi/agent/skills,
        # ~/.agents/skills, .pi/skills, and .agents/skills up the tree; a
        # repository's .claude/skills is none of them, and settings.json cannot
        # add it, because entries in its `skills` array are enable/disable
        # patterns and a plain path is discarded. The extension answers pi's
        # resources_discover event with the launch directory's .claude/skills,
        # so a checkout that carries its own skills is picked up on the session
        # started inside it and nowhere else.
        foreignSkills.enable = true;

        # Prompt stash, chord keybindings and session shortcuts, first-party
        # rather than the two published packages it replaces: supi-extras and
        # input-shortcuts overlap heavily, each is missing half of what the
        # other has, and both draw a footer this setup already owns.
        #
        # The chord prefix is ctrl+s. pi binds that key only in overlay scopes
        # (app.session.toggleSort, app.models.save), never in the editor, and
        # its TUI runs raw mode, so the terminal's XOFF meaning does not apply.
        #
        # clipboardCommand is left at its default: wl-copy on linux.
        extras.enable = true;

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
          # pkgs.audiomemo comes from the flake's own overlay, so this is the
          # same build the `record` on PATH is.
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
          # reaches the store or pi's process environment. Mistral and
          # HuggingFace are absent
          # because no such secret exists in dotfiles-secrets; audiomemo reads
          # an unset variable as an unconfigured backend, which is the right
          # answer rather than a degraded one.
          keyFiles = {
            ELEVENLABS_API_KEY_FILE = ageKey "elevenlabs_api_key";
            DEEPGRAM_API_KEY_FILE = ageKey "deepgram_api_key";
            OPENAI_API_KEY_FILE = ageKey "openai_api_key";
          };
        };

        # The daily driver. Without these pi defaults --provider to google
        # and pins no model, which is how it wandered into Anthropic on the
        # first run here.
        #
        # Caveat, inherited from upstream and shared with modules/ai/codex.nix:
        # `settings` is jq-merged into ~/.pi/agent/settings.json on every
        # launch, so these win over an interactive /model or Ctrl+P choice the
        # next time pi starts. That is the trade for having the default live in
        # the flake rather than in a file the agent can rewrite.
        settings = {
          defaultProvider = "openai-codex";
          defaultModel = "gpt-6-astra";
          defaultThinkingLevel = "xhigh";

          # Regular, not fullscreen: fullscreen does not reflow when the
          # terminal window is resized, which on a tiling setup is most of the
          # time. Revisit if upstream fixes the resize handling.
          tuiMode = "regular";

          # Off by default anyway, but pinned rather than inherited: a default
          # is someone else's decision and it can change on an update.
          enableAnalytics = false;
          # This one ships on, and it pings on install and on every update.
          enableInstallTelemetry = false;

          # The startup banner is a wall of store paths on this host, since
          # every skill, prompt and extension arrives as one. Ctrl+O still
          # prints it on demand.
          quietStartup = true;
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
      };

      # ctrl+backspace deletes the previous word, which is what Claude Code and
      # Codex do in this terminal and what muscle memory expects. pi ships
      # `ctrl+w` and `alt+backspace` for the action and gives ctrl+backspace to
      # `app.session.deleteNoninvasive` instead, a different scope (the session
      # list) that the editor never sees.
      #
      # A binding REPLACES that action's defaults rather than adding to them, so
      # the two shipped keys are repeated here on purpose; dropping them would
      # trade one shortcut for two. pi only ever reads this file
      # (KeybindingsManager has loadFromFile and reload and no writer), so a
      # store symlink is safe.
      home.file.".pi/agent/keybindings.json" = lib.mkIf enabled {
        text = builtins.toJSON {
          "tui.editor.deleteWordBackward" = [
            "ctrl+w"
            "alt+backspace"
            "ctrl+backspace"
          ];
        };
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
