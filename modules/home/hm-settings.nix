# Host-side home-manager plumbing (was the inline per-host block in the
# legacy flake.nix). `os` forwards into both nixos and darwin, so this same
# aspect serves the MacBook once it migrates.
{ ... }:
{
  den.aspects.hm-settings.os =
    { pkgs, ... }:
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        # timestamped so reruns never collide. Must be a script, not an inline
        # snippet: home-manager word-splits the value and runs it without a
        # shell, and on NixOS it lands in a systemd Environment= line, where
        # %Y/%d/%H/%S are unit specifiers.
        backupCommand = pkgs.writeShellScript "hm-backup" ''
          mv "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"
        '';
      };
    };
}
