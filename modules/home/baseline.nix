# The shared home baseline: what every "full" home environment gets
# (workstations, the mac, and farum-azula; NOT the lean servers or the
# deck, which pick features individually). Replaces the old
# hosts/common/home/default.nix aggregator.
#
# git/fish/gh/gpg/starship are NOT listed here; they ride on the joe user
# aspect and reach every den host already.
{ den, ... }:
{
  den.aspects.home-baseline = {
    includes = [
      den.aspects."1password"
      den.aspects.attic
      den.aspects.cli-packages
      den.aspects.claude
      den.aspects.antigravity
      den.aspects.codex
      den.aspects.mcp
      den.aspects.notify
      den.aspects.bin
      den.aspects.audiomemo
    ];
  };
}
