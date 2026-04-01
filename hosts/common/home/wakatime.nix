{ pkgs, ... }:
{
  home.packages = [ pkgs.wakatime-cli ];

  home.file.".wakatime.cfg".text = ''
    [settings]
    api_url = https://waka.turnin.quest/api
    api_key_vault_cmd = cat /run/agenix/wakapi_api_key
  '';
}
