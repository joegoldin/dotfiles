let
  app = "/Applications/Rex.app";
in
{
  inherit app;
  cli = "${app}/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex";
}
