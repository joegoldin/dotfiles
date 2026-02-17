{
  pkgs,
  lib,
  dotfiles-assets,
}: {
  berkeley-mono-nerd-font = pkgs.stdenv.mkDerivation {
    name = "berkeley-mono-nerd-font";
    version = "2.002";

    src = dotfiles-assets;

    # Don't try to unpack the source, it's already a directory
    dontUnpack = true;

    # Skip configure and build phases
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      mkdir -p $out/share/fonts/truetype/berkeley-mono-nerd-font
      find "$src/fonts/berkeley-mono-nerd-font/ttf" -type f -name "*.ttf" -exec cp {} $out/share/fonts/truetype/berkeley-mono-nerd-font/ \;
      if [ -z "$(ls -A $out/share/fonts/truetype/berkeley-mono-nerd-font)" ]; then
        echo "Error: No .ttf files found in source"
        exit 1
      fi
    '';

    meta = with lib; {
      description = "Berkeley Mono Nerd Font patched with additional glyphs";
      platforms = platforms.all;
    };
  };
}
