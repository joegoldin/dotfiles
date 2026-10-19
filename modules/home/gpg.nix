{ ... }:
{
  den.aspects.gpg.homeManager =
    {
      lib,
      pkgs,
      ...
    }:
    {
      programs.gpg.enable = true;
      services.gpg-agent = {
        enable = true;
        pinentry.package = pkgs.pinentry-curses;
      };
      # gpg-agent --supervised only understands systemd socket activation, so
      # under launchd it exits 2 on every socket hit. gpg autostarts it instead.
      launchd.agents.gpg-agent.enable = lib.mkForce false;
    };
}
