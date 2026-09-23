# Personal defaults live in agent-skills; this module supplies host integration.
{ inputs, ... }:
let
  piSecrets = import "${inputs.dotfiles-secrets}/pi.nix";
in
{
  den.aspects.pi.homeManager =
    { pkgs, lib, ... }:
    let
      enabled = pkgs ? llm-agents;
      ageKey = name: "/run/agenix/${name}";
    in
    {
      imports = [ inputs.agent-skills.homeManagerModules.pi ];

      programs.pi.coding-agent = lib.mkIf enabled {
        enable = true;
        environment = {
          OPENROUTER_API_KEY.file = ageKey "openrouter_api_key";
        };
        voice = {
          enable = true;
          inherit (pkgs) audiomemo;
          keyFiles = {
            ELEVENLABS_API_KEY_FILE = ageKey "elevenlabs_api_key";
            DEEPGRAM_API_KEY_FILE = ageKey "deepgram_api_key";
            OPENAI_API_KEY_FILE = ageKey "openai_api_key";
          };
        };
      };

      # Command-backed keys override the environment, so use them only on
      # macOS, where the 1Password desktop integration can resolve them.
      programs.agent-skills.pi.providers = lib.mkIf (enabled && pkgs.stdenv.hostPlatform.isDarwin) {
        anthropic.apiKey = "!op read '${piSecrets.anthropicKeyRef}'";
        openai.apiKey = "!op read '${piSecrets.openaiKeyRef}'";
        openrouter.apiKey = "!op read '${piSecrets.openrouterKeyRef}'";
      };
    };
}
