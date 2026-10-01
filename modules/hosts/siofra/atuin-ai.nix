# Atuin AI: self-hosted backend for `atuin ai` (the `?` key on an empty
# prompt), so the shell's AI runs on our own API keys instead of Atuin Hub.
#
# atuin-ai-server only speaks chat completions, and OpenAI refuses function
# tools there for every GPT-6 model unless reasoning_effort is "none" (atuin
# sends tools on every turn). A loopback-only LiteLLM sits in between and
# serves chat completions on top of OpenAI's Responses API, where tools and
# reasoning work together.
#
#   client ──https──▶ Caddy ──▶ atuin-ai-server :8082 ──▶ LiteLLM :4000 ──▶ OpenAI Responses
#                                     └─▶ Brave (web_search), Firecrawl (web_scrape)
#
# The server is open unless AUTH_TOKEN is set, so it always is: clients send
# the same token from the `atuin_ai_api_token` agenix secret (see
# modules/home/atuin.nix). LiteLLM has no master key; it binds 127.0.0.1 only,
# which neither the internet nor the docker bridge can reach.
#
# DNS: atuinAiDomain needs an A record → siofra (DNS-only, like attic) so
# Caddy can get its Let's Encrypt cert.
{ inputs, ... }:
let
  dotfiles-secrets = inputs.dotfiles-secrets;

  litellmPort = 4000;
  serverPort = 8082; # 8080 = wings, 8081 = attic

  # Each entry becomes both a LiteLLM route and an atuin model alias. `model`
  # is the OpenAI ID; LiteLLM matches on it and atuin sends it verbatim.
  #
  # OpenAI only: Claude through LiteLLM's Anthropic translation failed once a
  # session carried tool history ("each tool_use must have a single result").
  models = [
    {
      model = "gpt-6.1-sol";
      name = "GPT-6.1 Sol";
      description = "Near-Astra quality at lower cost";
    }
    {
      model = "gpt-6-astra";
      name = "GPT-6 Astra";
      description = "Most capable";
    }
    {
      model = "gpt-6-sol";
      name = "GPT-6 Sol";
      description = "Balanced";
    }
    {
      model = "gpt-6-luna";
      name = "GPT-6 Luna";
      description = "Fastest";
    }
  ];
  defaultModel = "gpt-6.1-sol";
in
{
  den.aspects.siofra.nixos =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      domains = import "${dotfiles-secrets}/domains.nix";
      secret = name: {
        file = "${dotfiles-secrets}/${name}.age";
        mode = "0400";
      };

      serverConfig = (pkgs.formats.toml { }).generate "atuin-ai-config.toml" {
        port = serverPort;
        endpoint = "http://127.0.0.1:${toString litellmPort}/v1";
        default_model = defaultModel;
        request.body.stream_options.include_usage = true;
        models = map (m: {
          alias = m.model;
          inherit (m) name description model;
        }) models;
        web_tools = {
          brave_api_key.env = "BRAVE_API_KEY";
          firecrawl_api_key.env = "FIRECRAWL_API_KEY";
        };
      };

      envDir = "/run/atuin-ai";

      secretNames = [
        "openai_api_key"
        "atuin_ai_api_token"
        "brave_api_key"
        "firecrawl_api_key"
      ];
    in
    {
      # All four must be encrypted to siofra's host key (see secrets.nix).
      age.secrets = lib.genAttrs secretNames secret;

      # agenix only yields one bare value per file and both services want
      # KEY=value env files, so assemble them as root before either starts.
      # PID 1 reads EnvironmentFile=, so LiteLLM's DynamicUser never needs
      # access to the agenix paths themselves.
      systemd.services.atuin-ai-env = {
        description = "Assemble Atuin AI env files from agenix secrets";
        after = [ "agenix.service" ];
        wants = [ "agenix.service" ];
        # Rekeying or editing a secret changes its store path; rebuild the env
        # files (and, via partOf below, restart the consumers) when that happens.
        restartTriggers = map (n: config.age.secrets.${n}.file) secretNames;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          RuntimeDirectory = "atuin-ai";
          RuntimeDirectoryMode = "0700";
          UMask = "0077";
        };
        script =
          let
            s = n: config.age.secrets.${n}.path;
          in
          ''
            printf 'OPENAI_API_KEY=%s\n' "$(cat ${s "openai_api_key"})" \
              > ${envDir}/litellm.env
            printf 'AUTH_TOKEN=%s\nBRAVE_API_KEY=%s\nFIRECRAWL_API_KEY=%s\n' \
              "$(cat ${s "atuin_ai_api_token"})" "$(cat ${s "brave_api_key"})" \
              "$(cat ${s "firecrawl_api_key"})" \
              > ${envDir}/server.env
          '';
      };

      services.litellm = {
        enable = true;
        host = "127.0.0.1";
        port = litellmPort;
        environmentFile = "${envDir}/litellm.env";
        settings.model_list = map (m: {
          model_name = m.model;
          litellm_params = {
            # The responses/ route is what lets tools and reasoning coexist.
            model = "openai/responses/${m.model}";
            api_key = "os.environ/OPENAI_API_KEY";
          };
        }) models;
      };

      virtualisation.oci-containers = {
        backend = "docker";
        containers.atuin-ai = {
          # Upstream publishes only `latest`/`main`; pin the digest so a deploy
          # never silently changes the server. Bump: see `docker buildx
          # imagetools inspect ghcr.io/atuinsh/atuin-ai-server:latest`.
          image = "ghcr.io/atuinsh/atuin-ai-server@sha256:3d11028588ebfddb0685169e35cbc7121d3577b6eee3831e845fbe5c28e48d92";
          volumes = [ "${serverConfig}:/etc/atuin-ai/config.toml:ro" ];
          environmentFiles = [ "${envDir}/server.env" ];
          # Host networking so it can reach LiteLLM on 127.0.0.1. Bandit binds
          # every interface, but :8082 isn't in the firewall's allow list, so
          # only Caddy (and the trusted tailnet) can reach it.
          extraOptions = [ "--network=host" ];
        };
      };

      systemd.services.litellm = {
        requires = [ "atuin-ai-env.service" ];
        after = [ "atuin-ai-env.service" ];
        partOf = [ "atuin-ai-env.service" ];
      };
      systemd.services.docker-atuin-ai = {
        requires = [
          "atuin-ai-env.service"
          "litellm.service"
        ];
        after = [
          "atuin-ai-env.service"
          "litellm.service"
        ];
        partOf = [ "atuin-ai-env.service" ];
      };

      # Caddy already runs on this box (wings.nix); this just adds the vhost.
      # flush_interval -1 so chat streams reach the client token by token.
      services.caddy.virtualHosts."${domains.atuinAiDomain}" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:${toString serverPort} {
            flush_interval -1
          }
        '';
      };
    };
}
