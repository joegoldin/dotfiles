{ dotfiles-secrets, ... }:
let
  domains = import "${dotfiles-secrets}/domains.nix";
in
{
  enable = true;
  enableFishIntegration = true;
  enableBashIntegration = true;
  settings = {
    auto_sync = true;
    sync_frequency = "5m";
    sync_address = "https://${domains.atuinDomain}";
    search_mode = "fuzzy";
    enter_accept = true;
    inline_height = 20;
    filter_mode = "session-preload";
    filter_mode_shell_up_key_binding = "session-preload";
    accept_with_backspace = true;
    accept_past_line_start = true;
    command_chaining = true;
  };
}
