# A KiCad PCM *library* package (symbols/footprints/3D models) from an upstream
# release zip.
#
# Library packages cannot go through kicad's `addons` argument: that path files
# every top-level directory of the zip under share/kicad/scripting/, which is
# where KiCad looks for plugins and nowhere it looks for libraries. Instead this
# reproduces the on-disk layout the PCM itself installs --
# 3rdparty/{symbols,footprints,3dmodels}/<identifier with dots as underscores>
# -- so the generated lib tables can address the libraries through
# ${KICAD10_3RD_PARTY} exactly as PCM-written tables do.
{
  lib,
  stdenvNoCC,
  unzip,

  pname,
  version,
  # The PCM zip: an upstream release artifact, or one nixpkgs already built.
  pcmZip,
  # Passed in rather than read out of metadata.json, so the lib-table generator
  # can name the directory without import-from-derivation.
  identifier,
  description,
  homepage,
  license,
}:
stdenvNoCC.mkDerivation {
  pname = "kicadlibrary-${pname}";
  inherit version;

  src = pcmZip;

  nativeBuildInputs = [ unzip ];

  unpackPhase = ''
    runHook preUnpack

    mkdir pcm
    unzip -q $src -d pcm

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    # PCM lists a package it finds in the 3rdparty tree whether or not it knows
    # anything about it -- directory name, version "0.0", author "<unknown>".
    # Keep the manifest so the aspect can hand it the real thing.
    install -Dm444 pcm/metadata.json \
      $out/share/kicad/3rdparty/pcm-metadata/${identifier}.json

    for kind in symbols footprints 3dmodels; do
      [ -d "pcm/$kind" ] || continue
      mkdir -p $out/share/kicad/3rdparty/$kind
      cp -r "pcm/$kind" $out/share/kicad/3rdparty/$kind/${
        builtins.replaceStrings [ "." ] [ "_" ] identifier
      }
    done

    runHook postInstall
  '';

  passthru = { inherit identifier; };

  meta = {
    inherit description homepage license;
    platforms = lib.platforms.all;
  };
}
