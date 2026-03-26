{ pkgs, inputs, ... }:
{
  home.sessionVariables = {
    EDITOR = "zeditor --wait";
    VISUAL = "zeditor --wait";
  };

  programs.zed-editor = {
    enable = true;
    package =
      inputs.zed-editor.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
        (old: {
          postPatch = (old.postPatch or "") + ''
            grep -q "impl FeatureFlag for GitGraphFeatureFlag" crates/feature_flags/src/flags.rs
            sed -i "/impl FeatureFlag for GitGraphFeatureFlag/,/^}/ s/^}/    fn enabled_for_all() -> bool { true }\n}/" crates/feature_flags/src/flags.rs
          '';
        });

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

      edit_predictions = {
        sweep = {
          privacy_mode = true;
        };
        provider = "zed";
        mode = "eager";
      };

      agent = {
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
        tree_view = false;
      };

      agent_servers = {
        claude-acp = {
          type = "registry";
          default_mode = "plan";
        };
      };
    };
  };
}
