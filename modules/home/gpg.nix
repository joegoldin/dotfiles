{ ... }:
{
  den.aspects.gpg.homeManager =
    {
      pkgs,
      ...
    }:
    {
      programs.gpg.enable = true;
      services.gpg-agent = {
        enable = true;
        pinentry.package = pkgs.pinentry-curses;
      };
    };
}
