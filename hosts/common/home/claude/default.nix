{
  pkgs,
  lib,
  inputs,
  ...
}: let
  enabled = pkgs ? llm-agents;

  # Get the latest claude-code from llm-agents
  claude-code-latest = pkgs.llm-agents.claude-code;

  # Get claude-nix library with explicitly overridden claude-code
  claudeLib = import "${inputs.claude-nix}/lib" {
    pkgs = pkgs.extend (
      final: prev: {
        claude-code = claude-code-latest;
      }
    );
  };

  # WSL-compatible notify-send wrapper (detects wsl-notify-send.exe at runtime)
  notifySendWrapper = pkgs.writeShellScriptBin "notify-send" ''
    # Wrapper that uses wsl-notify-send.exe on WSL
    if command -v wsl-notify-send.exe &> /dev/null; then
      # Convert notify-send args to wsl-notify-send format
      # notify-send [OPTIONS] SUMMARY [BODY] -> wsl-notify-send MESSAGE
      message=""
      for arg in "$@"; do
        case "$arg" in
          -*) ;; # Skip options
          *)
            if [ -z "$message" ]; then
              message="$arg"
            else
              message="$message: $arg"
            fi
            ;;
        esac
      done
      wsl-notify-send.exe --appId "Claude Code" -c "Claude Code" "''${message:-Notification}"
    else
      ${pkgs.libnotify}/bin/notify-send "$@"
    fi
  '';

  # Build code-notify package
  codeNotify = pkgs.callPackage ./code-notify.nix {};

  # Skills to extract from superpowers (upstream)
  skillNames = [
    "using-superpowers"
    "brainstorming"
    "receiving-code-review"
    "requesting-code-review"
    "subagent-driven-development"
    "systematic-debugging"
    "test-driven-development"
    "using-git-worktrees"
    "verification-before-completion"
    "writing-plans"
    "writing-skills"
  ];

  # Wrap an upstream skill
  wrapSkill = name:
    pkgs.runCommand "skill-${name}" {} ''
      mkdir -p $out/skills/${name}
      cp -r ${inputs.superpowers}/skills/${name}/* $out/skills/${name}/
    '';

  # Local skills (modified or custom)
  localSkill = name:
    pkgs.runCommand "skill-${name}" {} ''
      mkdir -p $out/skills/${name}
      cp -r ${./skills}/${name}/* $out/skills/${name}/
    '';

  # All skill derivations
  superpowersSkillDerivations =
    (map wrapSkill skillNames)
    ++ [
      (localSkill "claude-nix-config")
      (localSkill "executing-plans")
      (localSkill "gh-pr-review")
      (localSkill "obsidian-cli")
    ];

  # Custom commands
  prReviewCommand =
    claudeLib.mkCommand
    {
      name = "pr-review";
      description = "Fetch and analyze inline PR review comments for the current branch";
      allowed-tools = [
        "Bash"
        "Read"
        "Glob"
        "Grep"
        "Skill"
      ];
    }
    ''
      Invoke the gh-pr-review skill, then fetch and analyze inline PR review comments for the current branch.

      IMPORTANT: ghreview is a fish function. Always run it via: fish -c 'ghreview ...'
      Include bot comments by default (Copilot, etc.) — do NOT pass --no-bots unless the user asks.

      Steps:
      1. Use the Skill tool to load the gh-pr-review skill
      2. Run `fish -c 'ghreview --raw'` to get the full review JSON (includes code context by default)
      3. Summarize each reviewer's feedback (including bots like Copilot)
      4. List all unresolved comments grouped by file, with the referenced code and the reviewer's concern
      5. Categorize feedback (bugs, security, performance, style, architecture, questions)
      6. Propose a prioritized plan to address the comments

      If there are thread replies, note which comments already have responses and which are unanswered.

      $ARGUMENTS
    '';

  # Copy hooks from superpowers (includes session-start hook)
  superpowersHooks = pkgs.runCommand "superpowers-hooks" {} ''
    mkdir -p $out/hooks
    cp -r ${inputs.superpowers}/hooks/* $out/hooks/
    chmod +x $out/hooks/*.sh 2>/dev/null || true
  '';

  # Create the superpowers plugin using claude-nix
  superpowersPlugin = claudeLib.mkPlugin {
    name = "superpowers";
    description = "Core skills library: TDD, debugging, collaboration patterns, and proven techniques (from github:obra/superpowers)";
    skills = superpowersSkillDerivations;
    commands = [
      prReviewCommand
    ];
  };

  # Nix development plugin — MCP servers, LSP, skills, commands, agents
  nixPlugin = claudeLib.mkPlugin {
    name = "nix";
    description = "Nix development tools and helpers";
    mcpServers.nixos = {
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
    };
    lspServers.nix = {
      command = lib.getExe pkgs.nixd;
      extensionToLanguage = {
        ".nix" = "nix";
      };
    };
    skills = [
      (
        claudeLib.mkSkill
        {
          name = "nix-helper";
          description = "Helps with Nix development and formatting";
          allowed-tools = [
            "Bash(${pkgs.statix}/bin/statix)"
            "Bash(${pkgs.alejandra}/bin/alejandra)"
          ];
        }
        ''
          You are a Nix expert. When working with Nix files:

          1. ALWAYS run `${pkgs.statix}/bin/statix check .` to find anti-patterns
          2. ADDRESS all issues found
          3. ALWAYS format files with `${pkgs.alejandra}/bin/alejandra`

          Be pedantic about best practices and code quality.
        ''
      )
    ];
    commands = [
      (
        claudeLib.mkCommand
        {
          name = "format-nix";
          description = "Format all Nix files in the project";
          allowed-tools = [
            "Bash(${pkgs.alejandra}/bin/alejandra)"
            "Bash(${pkgs.fd}/bin/fd)"
          ];
          argument-hint = "[directory]";
        }
        ''
          Format all Nix files using alejandra.

          If an argument is provided, format files in that directory.
          Otherwise, format all .nix files in the current directory.

          Use: ${pkgs.fd}/bin/fd -e nix -x ${pkgs.alejandra}/bin/alejandra
        ''
      )
      (
        claudeLib.mkCommand
        {
          name = "nix-dotfiles";
          description = "Make changes to the NixOS/nix-darwin dotfiles with full repo context pre-loaded";
          argument-hint = "<what to change>";
        }
        ''
          You are working in a multi-platform Nix dotfiles repo. Use this context to make changes efficiently.

          ## Hosts

          | Host | Platform | Config dir |
          |------|----------|------------|
          | joe-desktop | NixOS (x86_64-linux), KDE Plasma 6 | hosts/nixos/ |
          | Joes-MacBook-Pro | macOS (aarch64-darwin) | hosts/darwin/ |
          | joe-wsl | NixOS on WSL | hosts/wsl/ |
          | oracle-cloud-bastion | NixOS server | hosts/oracle-cloud/ |
          | racknerd-cloud-agent | NixOS server | hosts/racknerd-cloud/ |

          ## Key Files — Where to make changes

          | What you want to do | File(s) to edit |
          |---------------------|-----------------|
          | Add a NixOS desktop package | hosts/nixos/packages.nix |
          | Add a common CLI package | hosts/common/home/packages.nix |
          | Define a custom package from source | hosts/common/system/pkgs/default.nix (or new .nix file there) |
          | Add a flake input | flake.nix (inputs section) |
          | Add an overlay | hosts/common/system/overlays/default.nix |
          | Configure a home-manager program | hosts/common/home/<program>.nix |
          | NixOS system config (services, boot, etc.) | hosts/nixos/joe-desktop.nix or hosts/nixos/configuration.nix |
          | macOS homebrew package | hosts/darwin/homebrew.nix |
          | macOS system settings | hosts/darwin/defaults.nix |
          | KDE Plasma config | hosts/nixos/plasma.nix |
          | Fish shell config | hosts/common/home/fish/ |
          | Git config | hosts/common/home/git.nix |

          ## Package Patterns (copy these)

          **Nixpkgs stable:** `pkgs.packageName`
          **Nixpkgs unstable:** `unstable.packageName` (overlay provides `pkgs.unstable.*`)
          **Custom package from GitHub (npm/yarn):** See `hosts/common/system/pkgs/default.nix` — `happy-cli` (yarn) or `lotion.nix` (npm/electron)
          **Custom package from GitHub (Go):** See `hosts/common/home/go.nix` — `claude-squad` using `buildGoModule`
          **Custom package from GitHub (binary):** See `hosts/common/home/sprites.nix` — platform-specific binary fetch
          **Custom Python package:** See `hosts/common/home/python/custom-pypi-packages.nix`
          **Shell wrapper:** See `google-chrome-stable` or `aws-cli` in `hosts/common/system/pkgs/default.nix`
          **Flake input package:** Add input to `flake.nix`, use via overlay or direct reference

          ## Overlays (hosts/common/system/overlays/default.nix)

          - `additions` — custom packages from `hosts/common/system/pkgs/`
          - `modifications` — patches to existing packages
          - `unstable-packages` — makes `pkgs.unstable.*` available
          - `llm-agents-packages` — Claude Code, Codex, Gemini CLI
          - `mcps-packages` — MCP servers

          ## Conventions

          - Formatter: alejandra (pre-commit hook enforced)
          - Lint: statix, gitleaks
          - Dual nixpkgs: stable (nixos-25.11) + unstable channel
          - Apply NixOS: `sudo nixos-rebuild switch --flake .`
          - Apply macOS: `darwin-rebuild switch --flake .`
          - Test build: `nix build .#packageName`

          ## Your task

          $ARGUMENTS

          Read the relevant files first, then make the changes. Follow existing patterns in the repo. Format changed .nix files with `${pkgs.alejandra}/bin/alejandra`.
        ''
      )
    ];
    agents = [
      (
        claudeLib.mkAgent
        {
          name = "nix-analyzer";
          description = "Specialized agent for analyzing Nix code";
          tools = [
            "Read"
            "Glob"
            "Grep"
            "Bash(${pkgs.statix}/bin/statix)"
          ];
        }
        ''
          You are an expert Nix code analyzer. When asked to analyze Nix code:

          1. Search for all .nix files in the project
          2. Run statix to identify anti-patterns
          3. Analyze the flake structure and dependencies
          4. Provide recommendations for improvements
          5. Explain any complex Nix patterns found

          Be thorough and educational in your analysis.
        ''
      )
    ];
  };

  # Attribution file for the plugin
  attributionFile = pkgs.writeTextFile {
    name = "superpowers-attribution";
    text = ''
      Skills in this plugin are sourced from:
      https://github.com/obra/superpowers

      Licensed under MIT License

      These skills are vendored and synced via:
      nix flake update superpowers
    '';
    destination = "/ATTRIBUTION";
  };

  # Complete plugin with hooks, attribution, and license
  superpowersPluginComplete = pkgs.buildEnv {
    name = "superpowers-complete";
    paths = [
      superpowersPlugin
      superpowersHooks
      attributionFile
      (pkgs.runCommand "superpowers-license" {} ''
        mkdir -p $out
        cp ${inputs.superpowers}/LICENSE $out/SUPERPOWERS-LICENSE
      '')
    ];
  };

  # Create wrapped claude binary with plugins using mkClaude (uses pkgsWithLatestClaude.claude-code)
  claudeWithPlugins = claudeLib.mkClaude {
    plugins = [
      superpowersPluginComplete
      nixPlugin
    ];
  };

  # Generate settings.json content
  settingsContent = import ./settings.nix {
    inherit codeNotify;
  };
in {
  # Add claude (with plugins) and code-notify to packages
  # notify-send wrapper handles WSL (wsl-notify-send.exe) vs native (libnotify)
  home.packages = lib.mkIf enabled [
    claudeWithPlugins
    codeNotify
    notifySendWrapper
  ];

  # Generate settings.json
  home.file.".claude/settings.json" = lib.mkIf enabled {
    text = builtins.toJSON settingsContent;
  };
}
