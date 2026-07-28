# Disk health monitoring. Added after the 2026-07-27 incident where sda
# silently stalled I/O for ~3 hours (13 GiB dirty, ext4 journal wedged)
# without a single kernel-visible device error — smartd gives us SMART
# self-test scheduling and syslog'd attribute changes so the next stall has
# a paper trail, and smartctl is on PATH for ad-hoc checks.
{ ... }:
{
  den.aspects.erdtree.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.smartmontools ];

      services.smartd = {
        enable = true;
        # DEVICESCAN with: monitor all attributes, schedule short self-tests
        # daily at 02:00 and long weekly (Sat 03:00), log to syslog only —
        # no mail plumbing on this host.
        defaults.monitored = "-a -o on -S on -s (S/../.././02|L/../../6/03)";
      };
    };
}
