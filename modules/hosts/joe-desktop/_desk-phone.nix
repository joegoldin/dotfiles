# Linksys CIT200 desk phone — reactive dataflow engine
{ config, ... }:
{
  services.desk-phone = {
    enable = true;
    enableService = false; # dev mode — just udev rules, run manually
    configFile = ./desk-phone.py; # create this when ready for service mode
    anthropicApiKeyFile = config.age.secrets.anthropic_api_key.path;
    deepgramApiKeyFile = config.age.secrets.deepgram_api_key.path;
    # elevenlabsApiKeyFile = config.age.secrets.elevenlabs_api_key.path;
  };
}
