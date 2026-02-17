{
  pkgs,
  lib,
  ...
}:
# Minimal devenv.nix
{
  # https://devenv.sh/reference/options/
  cachix.enable = false;
  dotenv.enable = true;

  packages = with pkgs;
    [
      hello
      fish
      # example packages
      # go
      # (writeShellScriptBin "google-chrome" ''
      #   exec -a $0 ${google-chrome}/bin/google-chrome-stable $@
      # '')
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # Linux specific packages
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      # macOS specific packages
    ];

  enterShell = ''
    # hello
  '';
}
