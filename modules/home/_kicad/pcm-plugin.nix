# A KiCad PCM plugin package built from an upstream release zip.
#
# KiCad's `addons` argument wants a derivation that drops the PCM zip at
# $out/${addonPath}; for plugins that upstream already publishes as a PCM
# package there is nothing to build, only a hash to pin. `addonPath` and
# `python3` come from kicad.callPackage and are re-`override`n by kicad when it
# takes the addon, so both must stay in the signature.
{
  lib,
  stdenvNoCC,
  python3,
  addonPath,

  pname,
  version,
  # The PCM zip as upstream publishes it.
  zip,
  description,
  homepage,
  license,
}:
stdenvNoCC.mkDerivation {
  pname = "kicadaddon-${pname}";
  inherit version;

  src = zip;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp $src $out/${addonPath}

    runHook postInstall
  '';

  meta = {
    inherit description homepage license;
    platforms = lib.platforms.all;
  };
}
