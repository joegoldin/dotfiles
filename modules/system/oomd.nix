# Tighten systemd-oomd so the userspace OOM killer acts before the system
# thrashes itself to death.
#
# Context: on 2026-04-29 a runaway `nix search nixpkgs '^dotnet'` (which
# evaluates the whole package set into RAM) put the desktop under sustained
# memory pressure for ~40 seconds before the machine froze. systemd-oomd
# was running but never fired because, by NixOS default, none of the
# enable*Slice options are on; so it had nothing to act on.
#
# This module:
#   1. Enables oomd monitoring on user, system, and root slices so the
#      cgroups containing user processes (Unity, cargo, nix evals, etc.)
#      are actually watched.
#   2. Shortens DefaultMemoryPressureDurationSec from 30s → 20s so oomd
#      reacts faster when PSI memory pressure stays above the limit.
{ ... }:
{
  den.aspects.oomd.nixos = _: {
    systemd.oomd = {
      enable = true;
      enableRootSlice = true;
      enableSystemSlice = true;
      enableUserSlices = true;

      # See oomd.conf(5). DefaultMemoryPressureLimit (60%) and SwapUsedLimit
      # (90%) are left at their defaults; only the duration is tightened.
      settings.OOM = {
        DefaultMemoryPressureDurationSec = "20s";
      };
    };
  };
}
