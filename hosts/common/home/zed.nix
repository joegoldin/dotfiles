{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # On Darwin, Zed comes from Homebrew (cask "zed"). We only manage settings,
  # keymaps, and the extension list there. Nix-built Zed + Roslyn dotnet
  # plumbing only run on Linux.
  isLinux = pkgs.stdenv.isLinux;

  # Zed's csharp extension ships a Roslyn LSP binary built against .NET 10.
  # On NixOS there is no /usr/share/dotnet for the apphost to discover, so we
  # provide a Nix-built dotnet runtime and point DOTNET_ROOT at it. dotnet-sdk_10
  # only landed in nixpkgs-unstable, so use the unstable overlay.
  dotnet = pkgs.unstable.dotnet-sdk_10;

  # Out-of-tree patches fetched from upstream PRs and applied on top of the
  # zed flake input. Each patch only touches workspace crate sources (not
  # deps), so cargoArtifacts stays cache-valid and only the final build
  # rebuilds. Pin to the commit hash (not the PR URL) so force-pushes can't
  # silently change the contents — the hash check would also catch it.
  zedPatches = [
    # https://github.com/zed-industries/zed/pull/54727 — let users rename
    # ACP threads locally even when the connection doesn't support
    # set_title (e.g. resume-only agents).
    (pkgs.fetchpatch {
      name = "zed-pr-54727-acp-title-editable.patch";
      url = "https://github.com/zed-industries/zed/commit/c4a633d52fd4b65e64219ef58971d409c271ca84.patch";
      hash = "sha256-/oD/mRa193EGlIZ5sp1rExlxzguM0aiQDpwEj72UgVA=";
    })
  ];

  zedPackage =
    inputs.zed-editor.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ zedPatches;
      });
in
{
  home.packages = lib.optionals isLinux [ dotnet ];

  home.sessionVariables = {
    EDITOR = if isLinux then "zeditor --wait" else "zed --wait";
    VISUAL = if isLinux then "zeditor --wait" else "zed --wait";
  }
  // lib.optionalAttrs isLinux {
    DOTNET_ROOT = "${dotnet}/share/dotnet";
  };

  programs.zed-editor = {
    enable = true;
    # null on Darwin → home-manager skips installing Zed but still manages
    # settings/keymaps/extensions for the Homebrew install.
    package = if isLinux then zedPackage else null;

    extensions = [
      "csharp"
      "csv"
      "dockerfile"
      "elisp"
      "elixir"
      "erlang"
      "fish"
      "git-firefly"
      "groovy"
      "helm"
      "html"
      "ini"
      "java"
      "just"
      "kotlin"
      "latex"
      "lua"
      "make"
      "neocmake"
      "nix"
      "powershell"
      "python-requirements"
      "rainbow-csv"
      "ruby"
      "scheme"
      "sql"
      "swift"
      "terraform"
      "toml"
      "xml"
      "wakatime"
      "zig"
    ];

    userKeymaps = [
      {
        context = "Workspace";
        bindings = {
          "shift shift" = "file_finder::Toggle";
        };
      }
      {
        context = "Editor && vim_mode == insert";
        bindings = { };
      }
      {
        context = "Editor && edit_prediction";
        bindings = {
          tab = "editor::AcceptEditPrediction";
        };
      }
      {
        context = "Terminal";
        bindings = {
          "shift-enter" = [
            "terminal::SendText"
            (builtins.fromJSON ''"\u001b\r"'')
          ];
        };
      }
      {
        bindings = {
          "ctrl-shift-`" = "terminal_panel::ToggleFocus";
          "cmd-q" = null;
          "cmd-q cmd-q" = "zed::Quit";
        };
      }
    ];

    userSettings = {
      telemetry = {
        diagnostics = false;
        metrics = false;
      };

      base_keymap = "VSCode";
      icon_theme = "Catppuccin Mocha";

      ui_font_size = 16;
      buffer_font_size = 15;
      buffer_font_family = "TX02 Nerd Font Mono";
      buffer_font_features = {
        calt = true;
      };

      terminal = {
        font_family = "TX02 Nerd Font Mono";
        show_count_badge = false;
        toolbar = {
          breadcrumbs = false;
        };
      };

      theme = {
        mode = "system";
        light = "One Light";
        dark = "Gruvbox Dark";
      };

      minimap = {
        show = "auto";
      };

      format_on_save = "on";
      hover_popover_delay = 750;
      auto_indent_on_paste = true;
      linked_edits = true;
      show_edit_predictions = true;
      confirm_quit = true;
      ensure_final_newline_on_save = true;
      colorize_brackets = true;
      cli_default_open_behavior = "existing_window";

      calls = {
        mute_on_join = true;
      };

      which_key = {
        enabled = true;
      };

      sticky_scroll = {
        enabled = true;
      };

      git = {
        inline_blame = {
          show_commit_summary = false;
        };
      };

      project_panel = {
        bold_folder_labels = false;
        diagnostic_badges = true;
        dock = "left";
        git_status_indicator = true;
      };

      outline_panel = {
        dock = "left";
      };

      collaboration_panel = {
        dock = "left";
      };

      edit_predictions = {
        sweep = {
          privacy_mode = true;
        };
        provider = "zed";
        mode = "eager";
      };

      agent = {
        dock = "right";
        enable_feedback = false;
        show_turn_stats = true;
        tool_permissions = {
          default = "allow";
        };
        default_model = {
          model = "claude-sonnet-4-6-thinking-latest";
          provider = "anthropic";
        };
        inline_assistant_model = {
          model = "claude-sonnet-4-6";
          provider = "zed.dev";
        };
        model_parameters = [ ];
      };

      file_types = {
        dotenv = [ ".env*" ];
        elixir = [ "*.ex" ];
      };

      diff_view_style = "split";

      git_panel = {
        collapse_untracked_diff = false;
        dock = "left";
        file_icons = false;
        show_count_badge = true;
        tree_view = true;
      };

      # External ACP agents — point them at our Nix-managed wrappers so Zed
      # launches the same binaries (with our skills, slash commands, plugins,
      # MCPs, etc.) that we use from the terminal.
      #
      # claude-acp: the adapter spawns Claude Code as a subprocess, so
      #   CLAUDE_CODE_EXECUTABLE redirects it to the home-manager-managed
      #   claude wrapper. That wrapper bakes in `--plugin-dir` flags for our
      #   agent-skills plugin (skills + commands + agents); pointing at the
      #   bare pkgs.llm-agents.claude-code binary instead would skip them.
      # claude-acp-work: same adapter (@agentclientprotocol/claude-agent-acp,
      #   the npm package Zed's registry uses), but as a `custom` entry so
      #   we get a second picker entry pointing at the claude-work wrapper
      #   (which sets CLAUDE_CONFIG_DIR=~/.claude-work for the work account).
      #   Custom-type instead of a second registry key because alternate
      #   registry keys silently fall back to defaults.
      # gemini: the "gemini" registry agent IS @google/gemini-cli invoked with
      #   --acp, so we override it with a custom entry pointing at our wrapped
      #   gemini binary. (gemini-nix doesn't add wrapper args — it manages
      #   ~/.gemini/ directly — so the bare binary is fine.)
      # codex-acp: statically links the codex Rust crates, so its bundled
      #   codex cannot be overridden at runtime. Zed's registry ships a generic
      #   Linux binary that fails on NixOS (libcap.so.2 not found), so point at
      #   the Nix-built codex-acp from llm-agents instead.
      agent_servers = {
        claude-acp = {
          type = "registry";
          default_mode = "plan";
          env = {
            CLAUDE_CODE_EXECUTABLE = "${config.home.profileDirectory}/bin/claude";
          };
        };
        claude-acp-work = {
          type = "custom";
          default_mode = "plan";
          command = "${pkgs.llm-agents.claude-code-acp}/bin/claude-agent-acp";
          args = [ ];
          env = {
            CLAUDE_CODE_EXECUTABLE = "${config.home.profileDirectory}/bin/claude-work";
          };
        };
        codex-acp = {
          type = "custom";
          command = "${pkgs.llm-agents.codex-acp}/bin/codex-acp";
          args = [ ];
          env = { };
        };
        gemini = {
          type = "custom";
          command = "${pkgs.llm-agents.gemini-cli}/bin/gemini";
          args = [ "--acp" ];
          env = { };
        };
      };

    }
    // lib.optionalAttrs isLinux {
      # Roslyn LSP (from the csharp extension) needs DOTNET_ROOT to find the
      # .NET runtime — NixOS doesn't ship /usr/share/dotnet. Set it explicitly
      # at the LSP level so Zed launched from a desktop file (no shell env)
      # still finds it.
      lsp = {
        roslyn = {
          binary = {
            env = {
              DOTNET_ROOT = "${dotnet}/share/dotnet";
            };
          };
        };
      };
    };
  };

  # Overlay our forked Nix extension's injections.scm for language injection
  # (fish/bash/python syntax highlighting in script body strings). Mac Zed
  # stores extensions under ~/Library/Application Support/Zed/, not XDG, so
  # this overlay is Linux-only.
  xdg.dataFile = lib.optionalAttrs isLinux {
    "zed/extensions/installed/nix/languages/nix/injections.scm".source =
      "${inputs.zed-nix-ext}/languages/nix/injections.scm";
  };
}
