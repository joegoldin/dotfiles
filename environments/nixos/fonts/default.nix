{
  pkgs,
  lib,
  ...
}: {
  berkeley-mono-nerd-font = pkgs.stdenv.mkDerivation {
    name = "berkeley-mono-nerd-font";
    version = "2.002";

    src = fetchGit {
      url = "git@github.com:joegoldin/dotfiles-assets.git";
      ref = "main";
      rev = "6c7f54cae6a6ccb67a7b9dd2b62b3597c6f25e9d";
    };

    installPhase = ''
      mkdir -p $out/share/fonts/truetype/berkeley-mono-nerd-font
      cp -r ./fonts/berkeley-mono-nerd-font/ttf/* $out/share/fonts/truetype/berkeley-mono-nerd-font
    '';
  };
}
