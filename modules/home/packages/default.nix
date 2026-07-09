{ den, ... }:
{
  den.aspects.cli-packages.includes = [
    den.aspects.audiomemo
    den.aspects.pueue
    den.aspects.shell-tools
    den.aspects.zmx
  ];

  den.aspects.cli-packages.homeManager =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (pkgs) unstable;
      pythonModule = import ../_python {
        inherit pkgs lib unstable;
        extraPackages = config.custom.python.extraPackages;
      };
      spritesModule = import ../_sprites.nix { inherit pkgs lib; };

      # Shared CLI packages for every host that imports modules/home/_hm;
      # including the cloud VMs. Heavier dev tooling shared between workstations
      # belongs in ./workstation.nix (imported per-host), not here. GUI apps are
      # host-specific by nature: Homebrew casks on darwin, the `gui` groups in
      # ./linux-workstation.nix and hosts/{nixos,volcano-manor}/packages on linux.
      #
      # Not listed here because dedicated modules provide them:
      #   audiomemo (programs.audiomemo), claude-code (../claude), codex (../codex),
      #   pueue (services.pueue via ../pueue.nix),
      # claude-container is added per-host (needs native build, no QEMU).
      packageGroups = with pkgs; {
        core = [
          bc
          btop # resource monitor (all boxes)
          coreutils
          file
          gawk
          gnumake
          gnupg
          gnused
          gnutar
          lsof
          p7zip
          pinentry-curses
          pv
          unzip
          watch
          which
          xdg-utils
          xz
          zip
          zlib
          zstd
        ];

        shell = [
          cowsay
          dua
          eza
          fish
          fzf # A command-line fuzzy finder
          glow # markdown previewer in terminal
          grc
          unstable.gum
          nnn # terminal file manager
          ripgrep # recursively searches directories for a regex pattern
          sysz # fzf terminal UI for systemctl
          tmux
          tree
          unstable.just
          vhs
        ];

        vcs = [
          act
          bfg-repo-cleaner
          git
          git-hunk
          git-stack
          git-worktree-switcher
          gitleaks
          pre-commit
          sem # semantic, entity-level git diff/impact/blame/context (tree-sitter)
        ];

        nix-tooling = [
          attic-client
          cachix
          unstable.devenv
          nil
          nix
          nix-output-monitor # nom: pretty nix build progress with percentage
          nix-your-shell
          nixd
          nixfmt
          statix
          treefmt
        ];

        containers = [
          helm-docs
          helm-ls
          helm-with-plugins
          helmfile-with-plugins
          k9s
          kubectl
          kubectx
          kubent
          lazydocker
          popeye
        ];

        cloud = [
          aws-cli
          caddy
          flyctl
          stripe-cli
        ];

        languages = [
          bun
          clojure
          elixir_1_18
          (lib.lowPrio erlang_27)
          leiningen
          (lib.lowPrio pipenv)
          pythonModule.packages
          typescript
          uv
          unstable.yarn-berry_3
          # rustup
        ];

        network = [
          aria2 # A lightweight multi-protocol & multi-source command-line download utility
          gping # ping, but with a graph
          httpie
          nmap
          socat # replacement of openbsd-netcat
          trippy
          wget
        ];

        media-docs = [
          unstable.asciinema
          unstable.hugo
          imagemagick
          unstable.marp-cli
          openring
          tesseract
          uxplay
          whisper-cpp
          yt-dlp
        ];

        data = [
          jq # A lightweight and flexible command-line JSON processor
          yq-go # yaml processer https://github.com/mikefarah/yq
        ];

        misc = [
          unstable.playwright-driver
          unstable.playwright-driver.browsers
          shopt-script
          spritesModule.packages.sprite
        ];
      };
    in
    {
      imports = [
      ];

      options.custom.python.extraPackages = lib.mkOption {
        type = lib.types.functionTo (lib.types.listOf lib.types.package);
        default = _ps: [ ];
        description = "Extra Python packages to include in the common environment";
      };

      config = {
        home.packages = lib.flatten (lib.attrValues packageGroups);
        home.activation.pythonPostInstall = pythonModule.pythonPostInstall;

        # Fish glue for tools this aspect installs, co-located so lean hosts
        # don't inherit abbrs for binaries they lack. Inert without fish.
        programs.fish = {
          shellAliases.ls = "eza -lA --group-directories-first -snew --icons=auto --git -h --hyperlink";

          shellAbbrs = {
            exa = "eza";
            lst = "eza -lath";

            awsswitch = "export AWS_PROFILE=(aws configure list-profiles | fzf)";
            awslogin = "aws sso login";

            k = "kubectl";
            lzd = "lazydocker";

            uxplay = "uxplay -p";
          };

          interactiveShellInit = ''
            set -gx PLAYWRIGHT_BROWSERS_PATH ${unstable.playwright-driver.browsers}
            set -gx PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS true

            # `llm` ships in the common python env (languages group)
            # from https://github.com/CGamesPlay/llm-cmd-comp/blob/main/share/llm-cmd-comp.fish
            bind \e\\ __llm_cmdcomp

            function __llm_cmdcomp -d "Fill in the command using an LLM"
              set __llm_oldcmd (commandline -b)
              set __llm_cursor_pos (commandline -C)
              echo # Start the program on a blank line
              set result (llm cmdcomp $__llm_oldcmd)
              if test $status -eq 0
                commandline -r $result
                echo # Move down a line to prevent fish from overwriting the program output
              end
              commandline -f repaint
            end
          '';
        };
      };
    };
}
