{
  pkgs,
  lib,
  ...
}: {
  programs.ssh = {
    enable = true;
    matchBlocks = {
      # default = {
      #   hostname = "*";
      # };
    };
    extraConfig = ''
    '';
  };
}
