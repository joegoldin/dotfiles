{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.wakatime-cli ];

  home.file.".wakatime.cfg".text = ''
    [settings]
    api_url = https://waka.turnin.quest/api
    api_key_vault_cmd = cat /run/agenix/wakapi_api_key
  '';

  # desktop-wakatime expects wakatime-cli at ~/.wakatime/wakatime-cli-linux-amd64
  home.file.".wakatime/wakatime-cli-linux-amd64".source =
    lib.getExe pkgs.wakatime-cli;
}
