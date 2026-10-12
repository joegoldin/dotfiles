# hosts/volcano-manor/home-manager.nix
{ ... }:
{
  den.aspects.volcano-manor.homeManager =
    { ... }:
    {
      imports = [
        ./_python.nix
        ./_plasma-panels.nix
      ];

      programs.plasma = {
        # volcano-manor specific hotkeys
        hotkeys.commands = {
          "launch-terminal" = {
            name = "Launch Ghostty";
            key = "Meta+Return";
            command = "ghostty";
          };
          "launch-browser" = {
            name = "Launch Zen";
            key = "Meta+B";
            command = "zen";
          };
        };
      };
    };
}
