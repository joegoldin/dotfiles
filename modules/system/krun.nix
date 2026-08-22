{ den, ... }:
{
  den.aspects.krun.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      libkrunSrc = pkgs.fetchFromGitHub {
        owner = "joegoldin";
        repo = "libkrun";
        rev = "0a88a81c78d5823841ff93b6008778ab787b8299";
        hash = "sha256-95s56vrSeHwEFRrHFijQvvhhU/mzJRQfQ6f0cUuhUGw=";
      };

      libkrunCargoDeps = pkgs.rustPlatform.fetchCargoVendor {
        src = libkrunSrc;
        hash = "sha256-SpxQZQAiQfH8u1rR+OaKtz7Mj6+wt2906xZjbb2qIj0=";
      };

      krunInit = pkgs.pkgsStatic.rustPlatform.buildRustPackage {
        pname = "krun-init";
        version = "0.1.0-2.0.0-dev";

        src = libkrunSrc;
        cargoDeps = libkrunCargoDeps;
        cargoBuildFlags = [
          "--package"
          "krun-init"
        ];
        doCheck = false;

        installPhase = ''
          runHook preInstall

          install -Dm755 \
            target/${pkgs.pkgsStatic.stdenv.hostPlatform.rust.rustcTarget}/release/krun-init \
            "$out/bin/krun-init"

          runHook postInstall
        '';
      };

      libkrunExec =
        (pkgs.libkrun.override {
          libkrunfw = pkgs.unstable.libkrunfw;
          withBlk = true;
          withNet = true;
        }).overrideAttrs
          (
            _finalAttrs: previousAttrs: {
              version = "2.0.0-unstable-2026-08-21";

              src = libkrunSrc;
              cargoDeps = libkrunCargoDeps;
              nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [ pkgs.rustfmt ];
              env = previousAttrs.env // {
                KRUN_INIT_BINARY_PATH = "${krunInit}/bin/krun-init";
              };
            }
          );

      crunKrun =
        (pkgs.crun.override {
          libkrun = libkrunExec;
          withLibkrun = true;
        }).overrideAttrs
          (
            _finalAttrs: previousAttrs: {
              version = "1.29.1-unstable-2026-08-21";

              buildInputs = previousAttrs.buildInputs ++ [ pkgs.json_c ];

              src = pkgs.fetchFromGitHub {
                owner = "joegoldin";
                repo = "crun";
                rev = "2fdda5710f8436687c417d4283997818960e0b71";
                hash = "sha256-AHiN6Rps4awrHNRKH0xAYuUqBAufNrDkseEksOk2f7o=";
                fetchSubmodules = true;
                leaveDotGit = true;
                postFetch = ''
                  cd "$out"
                  git rev-parse HEAD > COMMIT
                  rm -rf .git
                '';
              };

              postPatch = previousAttrs.postPatch + ''
                substituteInPlace src/libcrun/handlers/krun.c \
                  --replace-fail \
                    '"libkrun.so.2", "${libkrunExec}/lib/libkrun.so.1", NULL' \
                    '"${libkrunExec}/lib64/libkrun.so.2", NULL'
                substituteInPlace src/libcrun/handlers/krun.c \
                  --replace-fail \
                    '"libkrun_init.so.0", NULL' \
                    '"${libkrunExec}/lib64/libkrun_init.so.0", NULL'
              '';
            }
          );

      krunRuntime = pkgs.runCommand "krun-runtime-${crunKrun.version}" { } ''
        mkdir -p "$out/bin"
        ln -s ${lib.getExe crunKrun} "$out/bin/krun"
      '';
    in
    {
      assertions = [
        {
          assertion = config.virtualisation.docker.rootless.enable;
          message = "the krun aspect requires rootless Docker";
        }
      ];

      environment.systemPackages = [
        crunKrun
        krunRuntime
      ];

      virtualisation.docker.rootless.daemon.settings.runtimes.krun.path = "${krunRuntime}/bin/krun";
    };
}
