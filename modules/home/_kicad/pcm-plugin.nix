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
  unzip,
  zip,
  strip-nondeterminism,
  python3,
  addonPath,

  pname,
  version,
  # The PCM zip as upstream publishes it.
  pcmZip,
  # Shell run against the unpacked zip, for a plugin that has to be fixed up
  # before it can run from a read-only store path. When null the zip is passed
  # through byte for byte.
  patchScript ? null,
  description,
  homepage,
  license,
}:
stdenvNoCC.mkDerivation {
  pname = "kicadaddon-${pname}";
  inherit version;

  src = pcmZip;

  nativeBuildInputs = lib.optionals (patchScript != null) [
    unzip
    zip
    strip-nondeterminism
  ];

  dontUnpack = patchScript == null;

  unpackPhase = ''
    runHook preUnpack

    mkdir pcm
    unzip -q $src -d pcm

    runHook postUnpack
  '';

  buildPhase = ''
    runHook preBuild

    ${lib.optionalString (patchScript != null) ''
      pushd pcm
      ${patchScript}
      popd
    ''}

    runHook postBuild
  '';

  installPhase =
    if patchScript == null then
      ''
        runHook preInstall

        mkdir $out
        cp $src $out/${addonPath}

        runHook postInstall
      ''
    else
      ''
        runHook preInstall

        mkdir $out
        (cd pcm && zip -rqX $out/${addonPath} .)
        strip-nondeterminism --type zip $out/${addonPath}

        runHook postInstall
      '';

  meta = {
    inherit description homepage license;
    platforms = lib.platforms.all;
  };
}
