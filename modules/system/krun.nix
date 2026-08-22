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
        rev = "8a8a5f462d0e5c2752c91b91994484109551a952";
        hash = "sha256-c6p3zXfbvMdjzD/+vElpOcwJM3HTA0FU9CKhtehXJyk=";
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
                rev = "81c14a2b393c0deb6edbee02595f6837f4f718b0";
                hash = "sha256-N6JprgTvil4JLWVypioinQ7Fv0X7ETJme99seQJ1Sno=";
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
