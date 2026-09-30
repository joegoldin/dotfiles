# Evaluated at build time inside the drowse derivation from package.nix, after
# `crate2nix generate` has written Cargo.nix into the source tree. Store paths
# arrive as plain strings; builtins.storePath turns them back into build
# dependencies.
#
# Mirrors upstream's crane build (nix/build.nix in the zed-editor input):
# same toolchain, stdenv, native inputs, rustflags, environment and install
# layout, applied per crate through buildRustCrate overrides.
{
  cargoNix,
  root,
  name,
  version,
  toolchain,
  workspaceSource,
  livekit,
  fontsConf,
  commitSha,
  updateExplanation,
}:
let
  pkgs = import <nixpkgs> { };
  inherit (pkgs) lib;

  rust = builtins.storePath toolchain;
  source = builtins.storePath workspaceSource;

  # Upstream links with mold through clang and the LLVM bintools.
  zedStdenv =
    pkgs:
    lib.pipe pkgs.llvmPackages.stdenv [
      (
        stdenv:
        stdenv.override (old: {
          cc = old.cc.override { inherit (pkgs.llvmPackages) bintools; };
        })
      )
      pkgs.stdenvAdapters.useMoldLinker
    ];

  buildRustCrateForPkgs =
    pkgs:
    pkgs.buildRustCrate.override {
      rustc = rust;
      cargo = rust;
      stdenv = zedStdenv pkgs;
    };

  # Upstream's build inputs, given to every crate: buildRustCrate has no
  # workspace-wide equivalent, and working out which -sys crate needs which
  # library would not save rebuilds, since a nixpkgs bump changes them all.
  nativeInputs = with pkgs; [
    cmake
    curl
    perl
    pkg-config
    protobuf
    rustPlatform.bindgenHook
  ];
  libraries = with pkgs; [
    curl
    fontconfig
    freetype
    libgit2
    openssl
    sqlite
    zlib
    zstd
    alsa-lib
    glib
    libva
    libxkbcommon
    wayland
    vulkan-loader
    libglvnd
    libx11
    libxcb
    libdrm
    libgbm
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
  ];

  forEveryCrate = attrs: {
    nativeBuildInputs = (attrs.nativeBuildInputs or [ ]) ++ nativeInputs;
    buildInputs = (attrs.buildInputs or [ ]) ++ libraries;
    # .cargo/config.toml's rustflags, which buildRustCrate does not read.
    extraRustcOpts = (attrs.extraRustcOpts or [ ]) ++ [
      "-C"
      "symbol-mangling-version=v0"
      "--cfg"
      "tokio_unstable"
    ];
    PROTOC = "${pkgs.protobuf}/bin/protoc";
    dontUseCmakeConfigure = true;
    # buildRustCrate copies each build script's OUT_DIR into the lib output;
    # cxx-build leaves relative symlinks there that only resolved inside the
    # build tree. Nothing downstream reads them.
    dontCheckForBrokenSymlinks = true;
    # crate2nix does not pass Cargo's `readme` field through, so buildRustCrate
    # exports an empty CARGO_PKG_README and crates that include_str! their
    # README fail. Fill it in the way Cargo does: the manifest field, else a
    # README.md next to it.
    postConfigure = (attrs.postConfigure or "") + ''
      if [ -z "$CARGO_PKG_README" ]; then
        CARGO_PKG_README=$(sed -n 's/^readme *= *"\(.*\)"/\1/p' Cargo.toml | head -n1)
        if [ -z "$CARGO_PKG_README" ] && [ -e README.md ]; then
          CARGO_PKG_README=README.md
        fi
        export CARGO_PKG_README
      fi
    '';
  };

  # Workspace crates reach outside their own directory (rust-embed of
  # ../../assets, include_str! of sibling crates, build scripts reading the
  # workspace), so each builds from the whole tree and configures from its
  # member directory.
  forWorkspaceCrate =
    attrs:
    let
      origin = toString (attrs.src.origSrc or "");
    in
    lib.optionalAttrs (lib.hasPrefix "${root}/" origin) {
      src = source;
      workspace_member = lib.removePrefix "${root}/" origin;
      RELEASE_VERSION = version;
      ZED_COMMIT_SHA = commitSha;
      ZED_UPDATE_EXPLANATION = updateExplanation;
      FONTCONFIG_FILE = builtins.storePath fontsConf;
    };

  # Upstream's rpath libraries, plus libglvnd for the EGL that zed's build.rs
  # puts on the rpath for webrtc-sys to dlopen.
  gpuLibraries = with pkgs; [
    vulkan-loader
    wayland
    libva
    libglvnd
  ];

  byCrate = {
    # nixpkgs' livekit-libwebrtc is a shared library and webrtc-sys expects a
    # static one; the same build.rs patch upstream applies to its vendored copy.
    webrtc-sys = attrs: {
      LK_CUSTOM_WEBRTC = builtins.storePath livekit;
      postPatch = (attrs.postPatch or "") + ''
        substituteInPlace webrtc-sys/build.rs --replace-fail \
          "cargo:rustc-link-lib=static=webrtc" "cargo:rustc-link-lib=dylib=webrtc"

        substituteInPlace webrtc-sys/build.rs --replace-fail \
          'add_gio_headers(&mut builder);' \
          'for lib_name in ["glib-2.0", "gio-2.0"] {
              if let Ok(lib) = pkg_config::Config::new().cargo_metadata(false).probe(lib_name) {
                  for path in lib.include_paths {
                      builder.include(&path);
                  }
              }
          }'
      '';
    };

    # Cargo exports build-script metadata as DEP_<links key>_*, but
    # buildRustCrate names it after the crate (DEP_WASMTIME_C_API_IMPL_*) and
    # points it into the dependency's since-deleted build directory. The
    # headers themselves survive in the dependency's lib output.
    tree-sitter =
      attrs:
      let
        cApi = lib.findFirst (dep: dep.crateName == "wasmtime-c-api-impl") null (attrs.dependencies or [ ]);
      in
      lib.optionalAttrs (cApi != null) {
        DEP_WASMTIME_C_API_INCLUDE = "${cApi.lib}/lib/wasmtime-c-api-impl.out/include";
      };

    zstd-sys = _: {
      ZSTD_SYS_USE_PKG_CONFIG = true;
    };

    # The GPU libraries are dlopened at runtime, so fixup's rpath shrinking
    # drops them; add them back afterwards. (Upstream sets dontPatchELF
    # instead, which here would keep rpath entries pointing between this
    # crate's out and lib outputs and make them reference each other.)
    zed = attrs: {
      postFixup = (attrs.postFixup or "") + ''
        patchelf --add-rpath ${lib.makeLibraryPath gpuLibraries} $out/bin/zed
      '';
      # main.rs reads env!("CARGO_BIN_NAME"), which Cargo sets per binary
      # target and buildRustCrate does not set at all.
      CARGO_BIN_NAME = "zed";
    };
  };

  # nixpkgs' own override for a crate first, then ours on top of its result.
  crateOverride =
    crateName: attrs:
    let
      applyOver = acc: override: acc // override acc;
    in
    lib.foldl' applyOver attrs [
      (pkgs.defaultCrateOverrides.${crateName} or (_: { }))
      forEveryCrate
      forWorkspaceCrate
      (byCrate.${crateName} or (_: { }))
    ];

  crateNames = lib.unique (
    map (crate: crate.crateName) (lib.attrValues (import cargoNix { inherit pkgs; }).internal.crates)
  );

  project = import cargoNix {
    inherit pkgs buildRustCrateForPkgs;
    defaultCrateOverrides = lib.genAttrs crateNames crateOverride;
    extraTargetFlags.tokio_unstable = true;
  };

  zed = project.workspaceMembers.zed.build.override {
    features = [
      "default"
      "gpui_platform/runtime_shaders"
    ];
  };
  cli = project.workspaceMembers.cli.build;
in
# Upstream's Linux installPhase and postFixup.
pkgs.stdenvNoCC.mkDerivation {
  inherit name;
  src = source;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec
    cp ${zed}/bin/zed $out/libexec/zed-editor
    cp ${cli}/bin/cli $out/bin/zed
    ln -s $out/bin/zed $out/bin/zeditor

    install -D "crates/zed/resources/app-icon-nightly@2x.png" \
      "$out/share/icons/hicolor/1024x1024@2x/apps/zed.png"
    install -D crates/zed/resources/app-icon-nightly.png \
      $out/share/icons/hicolor/512x512/apps/zed.png

    (
      export DO_STARTUP_NOTIFY="true"
      export APP_CLI="zed"
      export APP_ICON="zed"
      export APP_NAME="Zed Nightly"
      export APP_ARGS="%U"
      mkdir -p "$out/share/applications"
      ${lib.getExe pkgs.envsubst} < "crates/zed/resources/zed.desktop.in" > "$out/share/applications/dev.zed.Zed-Nightly.desktop"
      chmod +x "$out/share/applications/dev.zed.Zed-Nightly.desktop"
    )

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/libexec/zed-editor --suffix PATH : ${lib.makeBinPath [ pkgs.nodejs_22 ]}
  '';
}
