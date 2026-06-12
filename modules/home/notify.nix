{ ... }:
{
  den.aspects.notify.homeManager =
    {
      pkgs,
      ...
    }:
    {
      home.packages = [ pkgs.libnotify ];
    };
}
