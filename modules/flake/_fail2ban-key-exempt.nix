# fail2ban can't exempt an SSH *key* directly — it bans at the firewall, before
# any key exchange — so "never ban me" is implemented as: before banning an IP,
# ask the journal whether that IP completed a successful publickey login in the
# last 30 days; if so, skip the ban (fail2ban's `ignorecommand`, exit 0 = ignore).
# One good key login from a network therefore makes it unbannable for a month.
#
# This guards the initrd trap on the encrypted boxes: while a box waits at the
# LUKS prompt, its initrd sshd only knows `root`, so a habitual `ssh joe@…` logs
# "Invalid user joe" — and fail2ban reads those failures out of the journal
# right after boot and bans the home IP. Imported into every host via
# den.default.nixos; a no-op unless the host enables fail2ban.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  ignoreKnownKey = pkgs.writeShellScript "fail2ban-ignore-known-key" ''
    # $1 = candidate IP (fail2ban substitutes <ip>). "port" anchors the match so
    # 1.2.3.4 can't match 1.2.3.45.
    ip="$1"
    [ -n "$ip" ] || exit 1
    ${pkgs.systemd}/bin/journalctl -q -u sshd.service --since "-30 days" \
      --grep "Accepted publickey" 2>/dev/null \
      | ${pkgs.gnugrep}/bin/grep -qF " from $ip port"
  '';
in
{
  config = lib.mkIf config.services.fail2ban.enable {
    services.fail2ban.jails.DEFAULT.settings = {
      ignorecommand = "${ignoreKnownKey} <ip>";
      # Cache verdicts so scanner floods don't fork journalctl per probe.
      ignorecache = ''key="<ip>", max-count=200, max-time=5m'';
    };
  };
}
