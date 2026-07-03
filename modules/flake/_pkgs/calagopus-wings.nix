# Calagopus Wings daemon (wings-rs) — the Rust node agent for the Calagopus
# panel. Upstream ships a fully static-pie (musl) binary per arch and even their
# own Docker image just copies it, so we fetch the release binary rather than
# building the Rust workspace from source (git dep on compact_str + aws-lc-rs +
# fat LTO make a source build a long yak-shave for the same artifact). Static =
# no interpreter, no patchelf needed. Bump `version` + hashes on new releases.
{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "1.0.11";
  sources = {
    x86_64-linux = {
      arch = "x86_64";
      hash = "sha256-TPJGLUSHlzJcxA19isb4Q/wqG7vUDpUU0l9EEv37FXk=";
    };
    aarch64-linux = {
      arch = "aarch64";
      hash = "sha256-c9EF8VnadFiUJPggS+OgvCtVS6JWehGhNDVX/Ryhb6s=";
    };
  };
  src =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "calagopus-wings: unsupported system ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "calagopus-wings";
  inherit version;

  src = fetchurl {
    url = "https://github.com/calagopus/wings/releases/download/release-${version}/wings-rs-${src.arch}-linux";
    inherit (src) hash;
  };

  dontUnpack = true;
  dontStrip = true; # upstream ships it stripped + static-pie

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/calagopus-wings"
    runHook postInstall
  '';

  meta = {
    description = "Calagopus Wings daemon (wings-rs) — Rust node agent for the Calagopus panel";
    homepage = "https://github.com/calagopus/wings";
    license = lib.licenses.mit;
    mainProgram = "calagopus-wings";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
