{ pkgs, ... }:
{
  home.sessionVariables = {
    EDITOR = "zeditor --wait";
    VISUAL = "zeditor --wait";
  };

  programs.zed-editor = {
    enable = true;
    package = pkgs.unstable.zed-editor;

    extensions = [
      "csharp"
      "csv"
      "dockerfile"
      "elisp"
      "elixir"
      "erlang"
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
      ensure_final_newline_on_save = true;

      features = {
        edit_prediction_provider = "zed";
      };

      file_types = {
        dotenv = [ ".env*" ];
        elixir = [ "*.ex" ];
      };

      agent_servers = {
        claude = {
          default_mode = "plan";
        };
      };
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/plain" = "dev.zed.Zed.desktop";
      "text/markdown" = "dev.zed.Zed.desktop";
      "text/x-csrc" = "dev.zed.Zed.desktop";
      "text/x-chdr" = "dev.zed.Zed.desktop";
      "text/x-c++src" = "dev.zed.Zed.desktop";
      "text/x-c++hdr" = "dev.zed.Zed.desktop";
      "text/x-java" = "dev.zed.Zed.desktop";
      "text/x-python" = "dev.zed.Zed.desktop";
      "text/x-script.python" = "dev.zed.Zed.desktop";
      "text/x-ruby" = "dev.zed.Zed.desktop";
      "text/x-shellscript" = "dev.zed.Zed.desktop";
      "text/x-sql" = "dev.zed.Zed.desktop";
      "text/css" = "dev.zed.Zed.desktop";
      "text/html" = "dev.zed.Zed.desktop";
      "text/xml" = "dev.zed.Zed.desktop";
      "application/json" = "dev.zed.Zed.desktop";
      "application/x-yaml" = "dev.zed.Zed.desktop";
      "application/toml" = "dev.zed.Zed.desktop";
      "application/xml" = "dev.zed.Zed.desktop";
      "application/javascript" = "dev.zed.Zed.desktop";
      "application/x-shellscript" = "dev.zed.Zed.desktop";
    };
  };
}
