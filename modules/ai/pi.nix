# Personal defaults live in agent-skills; this module supplies host integration.
{ inputs, ... }:
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
    };
}
