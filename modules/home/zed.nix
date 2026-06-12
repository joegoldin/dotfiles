{ inputs, ... }:
{
  den.aspects.zed.homeManager =
    {
      lib,
      pkgs,
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

      zedPackage = inputs.zed-editor.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
              "ctrl-s" = [
                "terminal::SendKeystroke"
                "ctrl+s"
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
            allow_data_collection = "no";
          };

          agent = {
            notify_when_agent_waiting = "primary_screen";
            dock = "right";
            enable_feedback = false;
            show_turn_stats = true;
            tool_permissions = {
              default = "allow";
            };
            default_model = {
              model = "claude-opus-4-7";
              provider = "zed.dev";
            };
            inline_assistant_model = {
              model = "claude-opus-4-7";
              provider = "zed.dev";
            };
            # Workaround for https://github.com/zed-industries/zed/issues/49222;
            # commit_message_model fallback to default_model was unreliable, so set
            # it explicitly.
            commit_message_model = {
              model = "claude-opus-4-7";
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

        }
        // lib.optionalAttrs isLinux {
          # Roslyn LSP (from the csharp extension) needs DOTNET_ROOT to find the
          # .NET runtime; NixOS doesn't ship /usr/share/dotnet. Set it explicitly
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
    };
}
