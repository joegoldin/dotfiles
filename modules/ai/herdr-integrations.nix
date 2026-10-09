{ inputs, den, ... }:
let
  assets = "${inputs.herdr}/src/integration/assets";
  hook =
    pkgs: agent:
    pkgs.writeText "herdr-agent-state.sh" (
      builtins.replaceStrings
        [ "set -eu" ]
        [
          ''
            set -eu
            export PATH="${
              pkgs.lib.makeBinPath [
                pkgs.python3
                pkgs.coreutils
              ]
            }:$PATH"
          ''
        ]
        (builtins.readFile "${assets}/${agent}/herdr-agent-state.sh")
    );
in
{
  den.aspects = {
    pi.includes = [ den.aspects.herdr-pi ];
    claude.includes = [ den.aspects.herdr-claude ];
    codex.includes = [ den.aspects.herdr-codex ];

    herdr-pi.homeManager = {
      home.file.".pi/agent/extensions/herdr-agent-state.ts".source = "${assets}/pi/herdr-agent-state.ts";
    };

    herdr-claude.homeManager = { config, pkgs, ... }: {
      home.file.".claude/hooks/herdr-agent-state.sh".source = hook pkgs "claude";
      programs.claude-nix.extraHooks.SessionStart = [
        {
          matcher = "";
          hooks = [
            {
              type = "command";
              command = "${pkgs.runtimeShell} \"${config.home.homeDirectory}/.claude/hooks/herdr-agent-state.sh\" session";
              timeout = 10;
            }
          ];
        }
      ];
    };

    herdr-codex.homeManager =
      { config, pkgs, ... }:
      let
        codexLib = inputs.agent-skills.inputs.codex-nix.lib.${pkgs.stdenv.hostPlatform.system};
      in
      {
        home.file.".codex/herdr-agent-state.sh".source = hook pkgs "codex";
        programs.codex-nix = {
          settings.features.hooks = true;
          plugins = [
            (codexLib.mkPlugin {
              name = "herdr";
              hooks = [
                (codexLib.mkHook {
                  event = "SessionStart";
                  matcher = "";
                  name = "herdr-session";
                  command = "${pkgs.runtimeShell} \"${config.home.homeDirectory}/.codex/herdr-agent-state.sh\" session";
                  timeout = 10;
                })
              ];
            })
          ];
        };
      };
  };
}
