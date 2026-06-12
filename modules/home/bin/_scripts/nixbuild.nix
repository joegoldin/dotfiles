{ pkgs }:
{
  name = "nixbuild";
  desc = "Open the nixbuild.net admin shell (rlwrap + ssh)";
  runtimeInputs = [
    pkgs.rlwrap
    pkgs.openssh
  ];
  examples = [
    {
      cmd = "nixbuild";
      desc = "Open the interactive admin shell";
    }
  ];
  fish = ''
    exec rlwrap ssh eu.nixbuild.net shell
  '';
}
