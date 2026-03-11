# YepAnywhere client service (defaults to off)
# CLI control: hosts/common/home/bin/scripts/yep.nix
{
  pkgs,
  username,
  dotfiles-secrets,
  ...
}:
let
  domains = import "${dotfiles-secrets}/domains.nix";
  yepanywhere = pkgs.callPackage ../common/system/pkgs/yepanywhere { };
  yepConfigDir = "/home/${username}/.yep-anywhere";
in
{
  age.secrets.yep-remote-access-json = {
    file = "${dotfiles-secrets}/yep-remote-access.json.age";
    mode = "0400";
    owner = username;
  };

  # Copy agenix-decrypted secrets to ~/.yep-anywhere/ on activation
  home-manager.users.${username} =
    { lib, ... }:
    {
      home.activation.yepanywhereConfig =
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p ${yepConfigDir}
          cp /run/agenix/yep-remote-access-json ${yepConfigDir}/remote-access.json
          chmod 600 ${yepConfigDir}/remote-access.json
          echo '{"complete":true}' > ${yepConfigDir}/onboarding.json
        '';
    };

  systemd.services.yepanywhere = {
    description = "YepAnywhere client";
    after = [ "network.target" ];
    # No wantedBy — service defaults to off, use `yep on` to start

    serviceConfig = {
      User = username;
      Group = "users";
      WorkingDirectory = "/home/${username}";
      Environment = [
        "HOME=/home/${username}"
        "ALLOWED_HOSTS=${domains.yepRelayDomain}"
        "PATH=${pkgs.lib.makeBinPath [ pkgs.nodejs pkgs.llm-agents.claude-code ]}:/run/current-system/sw/bin"
      ];
      ExecStart = "${yepanywhere}/bin/yepanywhere";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
