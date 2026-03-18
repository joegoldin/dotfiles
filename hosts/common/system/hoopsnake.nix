# hosts/common/system/hoopsnake.nix
# Remote LUKS unlock via SSH over Tailscale using hoopsnake
{
  config,
  dotfiles-secrets,
  ...
}:
{
  # Decrypt hoopsnake secrets via agenix
  age.secrets.hoopsnake-host-key = {
    file = "${dotfiles-secrets}/hoopsnake-host-key.age";
    mode = "0400";
    owner = "root";
  };
  age.secrets.hoopsnake-ts-authkey = {
    file = "${dotfiles-secrets}/hoopsnake-ts-authkey.age";
    mode = "0400";
    owner = "root";
  };

  boot.initrd.network = {
    enable = true;

    hoopsnake = {
      enable = true;

      ssh = {
        authorizedKeysFile = builtins.toFile "hoopsnake-authorized-keys"
          (import "${dotfiles-secrets}/keys.nix").joe;
        privateHostKey = config.age.secrets.hoopsnake-host-key.path;
      };

      tailscale = {
        tags = [ "tag:hoopsnake" ];
        environmentFile = config.age.secrets.hoopsnake-ts-authkey.path;
        cleanup.deleteExisting = true;
      };
    };
  };
}
