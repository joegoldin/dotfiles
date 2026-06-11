# Free-memory-percentage-based OOM killer.
#
# systemd-oomd reacts to sustained PSI memory *pressure*, which is fine for
# slow leaks but can't keep up when something allocates very fast (e.g. a
# `nix search` evaluation pulls all of nixpkgs into RAM in seconds — see
# the 2026-04-29 lockup, where the system thrashed for 40s and froze
# without any kill firing).
#
# earlyoom watches absolute free RAM and free swap and SIGTERMs/SIGKILLs
# the biggest offender well before the kernel's own OOM logic kicks in.
_: {
  services.earlyoom = {
    enable = true;

    # On a 62 GB workstation:
    #   5% free  ≈ 3.1 GB → SIGTERM the biggest memory hog
    #   2% free  ≈ 1.2 GB → SIGKILL it
    # These trigger before the kernel has to thrash the disk on the
    # 8 GB partition swap.
    freeMemThreshold = 5;
    freeMemKillThreshold = 2;
    freeSwapThreshold = 10;
    freeSwapKillThreshold = 5;

    # Surface kills via the system D-Bus so we actually notice when
    # something gets reaped. Caveat from the module: any local user
    # can spam notifications, so only safe on single-user systems.
    enableNotifications = true;

    extraArgs = [
      # Prefer killing the usual memory pigs first.
      "--prefer"
      "(^|/)(nix|nix-daemon|cargo|rustc|node|electron|chromium|zen|zen-bin|Unity|java)$"
      # Never reap the things that keep the session alive.
      "--avoid"
      "(^|/)(systemd|dbus|kwin_wayland|plasmashell|plasma-session|sddm|sshd|init|kthreadd|Xwayland)$"
    ];
  };
}
