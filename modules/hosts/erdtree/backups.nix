# Nightly restic backups to B2. Retain the backup repository and back up the
# Hydra database, not the rebuildable Nix store or build logs.
{ inputs, ... }:
let
  inherit (inputs) dotfiles-secrets;
in
{
  den.aspects.erdtree.nixos =
    { config, ... }:
    let
      inherit (import "${dotfiles-secrets}/garnix.nix") b2;
      repository = "s3:https://${b2.endpoint}/${b2.backupBucket}/erdtree";
      environmentFile = config.age.secrets.garnix-restic-env.path;
      passwordFile = config.age.secrets.garnix-restic-password.path;
    in
    {
      age.secrets.garnix-restic-env.file = "${dotfiles-secrets}/garnix-restic-env.age";
      age.secrets.garnix-restic-password.file = "${dotfiles-secrets}/garnix-restic-password.age";

      services = {
        postgresqlBackup = {
          enable = true;
          databases = [ "hydra" ];
        };

        restic.backups = {
          b2 = {
            inherit repository environmentFile passwordFile;
            initialize = true;
            paths = [ config.services.postgresqlBackup.location ];
            timerConfig = {
              OnCalendar = "03:30";
              RandomizedDelaySec = "15m";
              Persistent = true;
            };
            pruneOpts = [
              "--keep-daily 7"
              "--keep-weekly 4"
              "--keep-monthly 6"
            ];
          };

          # Run an integrity check even when there are no new backups.
          b2-check = {
            inherit repository environmentFile passwordFile;
            paths = [ ];
            timerConfig = {
              OnCalendar = "Sun 05:00";
              Persistent = true;
            };
            runCheck = true;
            checkOpts = [ "--read-data-subset=5%" ];
          };
        };
      };
    };
}
