# Personal defaults live in agent-skills; this module supplies host integration.
{ inputs, ... }:
{
  den.aspects.pi.homeManager =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      enabled = pkgs ? llm-agents;
      secrets = osConfig.age.secrets or { };
      ageKey = name: secrets.${name}.path or null;
    in
    {
      imports = [ inputs.agent-skills.homeManagerModules.pi ];

      programs.pi.coding-agent = lib.mkIf enabled {
        enable = true;
        minimap.enable = true;
        # Match the shared profile's priority so this adds to its defaults.
        extensionPackages = lib.mkDefault [
          inputs.agent-skills.inputs.pi-nix.packages.${pkgs.stdenv.hostPlatform.system}.ext-pi-mcp-adapter
          inputs.agent-skills.inputs.pi-nix.packages.${pkgs.stdenv.hostPlatform.system}.ext-aliou-pi-synthetic
          inputs.agent-skills.inputs.pi-nix.packages.${pkgs.stdenv.hostPlatform.system}.ext-pi-provider-umans
        ];
        # The adapter reads shared .mcp.json and Pi's existing MCP files.
        # Keep codemode from the shared profile, but only one MCP client.
        settings = {
          extensions = [ "-builtin:mcp" ];
          # settings is an untyped attrset: lists replace rather than merge.
          # Retain the shared profile's scope before adding these providers.
          defaultModel = "gpt-6.1-sol";
          enabledModels = [
            "openai/gpt-6-astra"
            "openai/gpt-6.1-sol"
            "openai/gpt-6-luna"
            "cerebras/qwen-3.8-27b"
            "synthetic/hf:zai-org/GLM-5.3"
            "synthetic/hf:zai-org/GLM-5.3-Flash"
            "synthetic/hf:deepseek-ai/DeepSeek-V4.1-Flash-1017"
            "synthetic/hf:moonshotai/Kimi-K3"
            "umans/umans-deepseek-v4.1-flash"
            "umans/umans-glm-5.3"
            "umans/umans-kimi-k3"
          ];
        };
        environment = lib.filterAttrs (_: key: key.file != null) {
          OPENROUTER_API_KEY.file = ageKey "openrouter_api_key";
          CEREBRAS_API_KEY.file = ageKey "cerebras_api_key";
        };
        voice = {
          enable = true;
          inherit (pkgs) audiomemo;
          keyFiles = lib.filterAttrs (_: path: path != null) {
            ELEVENLABS_API_KEY_FILE = ageKey "elevenlabs_api_key";
            DEEPGRAM_API_KEY_FILE = ageKey "deepgram_api_key";
            OPENAI_API_KEY_FILE = ageKey "openai_api_key";
          };
        };
      };
    };
}
