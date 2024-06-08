{pkgs, ...}:

{
  plugins = [
    { name = "z"; src = pkgs.fishPlugins.z.src; }
    { name = "tide"; src = pkgs.fishPlugins.tide.src; }
    { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
  ];
}
