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
      ageKey = name: "/run/agenix/${name}";
      cerebrasEnabled = (osConfig.age.secrets or { }) ? cerebras_api_key;
    in
    {
      imports = [ inputs.agent-skills.homeManagerModules.pi ];

      programs.pi.coding-agent = lib.mkIf enabled {
        enable = true;
        extensionPackages = [
          inputs.agent-skills.inputs.pi-nix.packages.${pkgs.stdenv.hostPlatform.system}.ext-pi-mcp-adapter
        ];
        # The adapter reads shared .mcp.json and Pi's existing MCP files.
        # Keep codemode from the shared profile, but only one MCP client.
        settings.extensions = [ "-builtin:mcp" ];
        environment = {
          OPENROUTER_API_KEY.file = ageKey "openrouter_api_key";
          CEREBRAS_API_KEY = lib.mkIf cerebrasEnabled {
            file = ageKey "cerebras_api_key";
          };
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
    };
}
