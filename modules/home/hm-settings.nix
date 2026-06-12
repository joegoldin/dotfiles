# Host-side home-manager plumbing (was the inline per-host block in the
# legacy flake.nix). `os` forwards into both nixos and darwin, so this same
# aspect serves the MacBook once it migrates.
{ ... }:
{
  den.aspects.hm-settings.os = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      # timestamped so reruns never collide
      backupCommand = ''mv "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"'';
    };
  };
}
