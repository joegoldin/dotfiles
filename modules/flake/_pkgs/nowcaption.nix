{
  lib,
  python3,
  fetchFromGitHub,
  fetchurl,
  wrapGAppsHook4,
  gobject-introspection,
  gtk4,
  gtk4-layer-shell,
  libadwaita,
  gst_all_1,
}:
let
  asrModel = fetchurl {
    url = "https://github.com/Techlm77/NowCaption/releases/download/models-v1/nowcaption-fastconformer-en-80ms-cc-by-v1.tar.bz2";
    hash = "sha256-hXY5+B2opSEQ1lny0akbxcJfASL0b9M1gJEJa3SmzoA=";
  };
  punctModel = fetchurl {
    url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/punctuation-models/sherpa-onnx-online-punct-en-2024-08-06.tar.bz2";
    hash = "sha256-n15acsfSgpY1vQdPzpK2u9W3jailLnrY7RvpM/NmuZ0=";
  };
  musicFilterModel = fetchurl {
    url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/speech-enhancement-models/dpdfnet2.onnx";
    hash = "sha256-zjXWAl/HHfDvENFUDht5FoN7v+X2iW3rdEUI0srUh6k=";
  };
in
python3.pkgs.buildPythonApplication rec {
  pname = "nowcaption";
  version = "1.1.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "Techlm77";
    repo = "NowCaption";
    tag = "v${version}";
    hash = "sha256-drPGHX2R5eM8MBNhWvp7Rq003pbVDT3/m+qITPyP9Wc=";
  };

  build-system = with python3.pkgs; [ setuptools ];

  nativeBuildInputs = [
    wrapGAppsHook4
    gobject-introspection
  ];

  buildInputs = [
    gtk4
    gtk4-layer-shell
    libadwaita
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    # pulsesrc, which captures the desktop monitor or the microphone
    gst_all_1.gst-plugins-good
  ];

  dependencies = with python3.pkgs; [
    sherpa-onnx
    numpy
    pygobject3
    pycairo
  ];

  # nixpkgs' sherpa-onnx installs the module without dist-info metadata, so
  # the runtime deps check cannot see it even though it imports.
  pythonRemoveDeps = [ "sherpa-onnx" ];

  # Same layout the Flatpak installs, minus the punctuation archive's unused
  # fp32 model.
  postInstall = ''
    models=$out/share/nowcaption/models
    tar xjf ${asrModel} -C $TMPDIR
    tar xjf ${punctModel} -C $TMPDIR
    install -Dm644 -t $models/nowcaption-fastconformer-en-80ms-cc-by-v1 \
      $TMPDIR/nowcaption-fastconformer-en-80ms-cc-by-v1/{tokens.txt,encoder.int8.onnx,decoder.int8.onnx,joiner.int8.onnx,README.md}
    install -Dm644 -t $models/sherpa-onnx-online-punct-en-2024-08-06 \
      $TMPDIR/sherpa-onnx-online-punct-en-2024-08-06/{model.int8.onnx,bpe.vocab,README.md}
    install -Dm644 ${musicFilterModel} $models/dpdfnet2/dpdfnet2.onnx

    install -Dm644 data/io.github.Techlm77.NowCaption.desktop -t $out/share/applications
    install -Dm644 data/io.github.Techlm77.NowCaption.metainfo.xml -t $out/share/metainfo
    install -Dm644 data/icons/io.github.Techlm77.NowCaption.svg -t $out/share/icons/hicolor/scalable/apps
  '';

  dontWrapGApps = true;

  # launch.py looks for gtk4-layer-shell in FHS paths and re-execs with it
  # preloaded, which finds nothing on NixOS, and its `python -m nowcaption`
  # re-exec would lose the wrapped script's sys.path anyway. Preload it here
  # instead, as the Flatpak launcher does, so the caption window can float
  # above others on Wayland. Unconditional because the binary wrapper has no
  # --run; under X11 it only shims libwayland-client calls nothing makes.
  preFixup = ''
    makeWrapperArgs+=(
      "''${gappsWrapperArgs[@]}"
      --set NOWCAPTION_MODELS $out/share/nowcaption/models
      --set NOWCAPTION_REEXEC 1
      --prefix LD_PRELOAD " " ${gtk4-layer-shell}/lib/libgtk4-layer-shell.so.0
    )
  '';

  pythonImportsCheck = [ "nowcaption.engine" ];

  meta = {
    description = "On-device live captions for Linux desktop audio or the microphone";
    homepage = "https://github.com/Techlm77/NowCaption";
    license = with lib.licenses; [
      mit
      # models
      cc-by-40
      asl20
    ];
    mainProgram = "nowcaption";
    platforms = lib.platforms.linux;
  };
}
