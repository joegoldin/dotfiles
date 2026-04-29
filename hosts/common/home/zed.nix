{ pkgs, inputs, ... }:
let
  # Zed's csharp extension ships a Roslyn LSP binary built against .NET 10.
  # On NixOS there is no /usr/share/dotnet for the apphost to discover, so we
  # provide a Nix-built dotnet runtime and point DOTNET_ROOT at it. dotnet-sdk_10
  # only landed in nixpkgs-unstable, so use the unstable overlay.
  dotnet = pkgs.unstable.dotnet-sdk_10;
in
{
  home.packages = [ dotnet ];

  home.sessionVariables = {
    EDITOR = "zeditor --wait";
    VISUAL = "zeditor --wait";
    DOTNET_ROOT = "${dotnet}";
  };

  programs.zed-editor = {
    enable = true;
    package = inputs.zed-editor.packages.${pkgs.stdenv.hostPlatform.system}.default;

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

      # Roslyn LSP (from the csharp extension) needs DOTNET_ROOT to find the
      # .NET runtime — NixOS doesn't ship /usr/share/dotnet. Set it explicitly
      # at the LSP level so Zed launched from a desktop file (no shell env)
      # still finds it.
      lsp = {
        roslyn = {
          binary = {
            env = {
              DOTNET_ROOT = "${dotnet}";
            };
          };
        };
      };
    };
  };

  # Overlay our forked Nix extension's injections.scm for language injection
  # (fish/bash/python syntax highlighting in script body strings)
  xdg.dataFile."zed/extensions/installed/nix/languages/nix/injections.scm".source =
    "${inputs.zed-nix-ext}/languages/nix/injections.scm";
}
