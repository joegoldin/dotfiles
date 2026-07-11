# Nightly restic backups to B2 (the repo's first backup infra — reuse this
# shape for other hosts). Covers: postgres dumps (written 4x/day by
# services.postgresqlBackup from the garnix database module) and raw build
# logs. OpenSearch indices are rebuildable and skipped. Restore drill:
# docs/plans/2026-07-10-garnix-self-hosting-phase1-plan.md Task 14.
{ inputs, ... }:
let
  dotfiles-secrets = inputs.dotfiles-secrets;
in
{
  den.aspects.erdtree.nixos =
    { config, lib, ... }:
    let
      garnixData = import "${dotfiles-secrets}/garnix.nix";
    in
    {
      age.secrets.garnix-restic-env.file = "${dotfiles-secrets}/garnix-restic-env.age";
      age.secrets.garnix-restic-password.file = "${dotfiles-secrets}/garnix-restic-password.age";

      services.restic.backups.b2 = {
        repository = "s3:https://${garnixData.b2.endpoint}/${garnixData.b2.backupBucket}/erdtree";
        environmentFile = config.age.secrets.garnix-restic-env.path;
        passwordFile = config.age.secrets.garnix-restic-password.path;
        initialize = true;
        paths = [
          "/var/backup/postgresql"
          "/var/lib/garnix/logs"
        ];
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

      # Weekly integrity check of the restic repo. runCheck/checkOpts verified
      # present on the pinned nixpkgs (nixos/modules/services/backup/restic.nix).
      services.restic.backups.b2-check = {
        repository = "s3:https://${garnixData.b2.endpoint}/${garnixData.b2.backupBucket}/erdtree";
        environmentFile = config.age.secrets.garnix-restic-env.path;
        passwordFile = config.age.secrets.garnix-restic-password.path;
        paths = [ ];
        timerConfig = {
          OnCalendar = "Sun 05:00";
          Persistent = true;
        };
        runCheck = true;
        checkOpts = [ "--read-data-subset=5%" ];
      };
    };
}
