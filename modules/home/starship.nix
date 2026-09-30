_: {
  den.aspects.starship.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.unstable.jj-starship ];

      programs.starship = {
        enable = true;

        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;
        enableNushellIntegration = true;

        settings = {
          command_timeout = 2000;

          # Lead the prompt with the zmx session name (only set inside zmx);
          # $all keeps every other module in its default position.
          format = "\${env_var.ZMX_SESSION}$all";

          aws = {
            format = "\\[[$symbol($profile)(\\($region\\))(\\[$duration\\])]($style)\\]";
          };

          bun = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          c = {
            format = "\\[[$symbol($version(-$name))]($style)\\]";
          };

          cmake = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          cmd_duration = {
            format = "\\[[⏱ $duration]($style)\\]";
          };

          cobol = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          conda = {
            format = "\\[[$symbol$environment]($style)\\]";
          };

          crystal = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          daml = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          dart = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          deno = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          docker_context = {
            format = "\\[[$symbol$context]($style)\\]";
          };

          dotnet = {
            format = "\\[[$symbol($version)(🎯 $tfm)]($style)\\]";
          };

          elixir = {
            format = "\\[[$symbol($version \\(OTP $otp_version\\))]($style)\\]";
          };

          elm = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          erlang = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          # jj-starship replaces the git_* modules: it renders both jj and
          # plain git repos, and in colocated jj repos (where git's HEAD is
          # always detached) shows the change id and bookmarks instead.
          custom.vcs = {
            when = "jj-starship detect";
            shell = [
              "jj-starship"
              "--no-jj-prefix"
              "--no-git-prefix"
            ];
            format = "\\[$output\\]";
          };

          env_var.ZMX_SESSION = {
            symbol = " ";
            format = "\\[[$symbol$env_value]($style)\\] ";
            description = "zmx session name";
            # Gruvbox bright orange — unused by any other prompt segment
            # (purple collides with the git branch color).
            style = "bold #fe8019";
          };

          gcloud = {
            format = "\\[[$symbol$account(@$domain)(\\($region\\))]($style)\\]";
            # Starship's default symbol is "☁️  " with two trailing spaces
            # (overhang padding for terminals that render the emoji too wide);
            # this terminal sizes it correctly, so one space is enough.
            symbol = "☁️ ";
          };

          git_branch.disabled = true;
          git_commit.disabled = true;
          git_status.disabled = true;

          golang = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          haskell = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          helm = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          hg_branch = {
            format = "\\[[$symbol$branch]($style)\\]";
          };

          java = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          julia = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          kotlin = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          kubernetes = {
            format = "\\[[$symbol$context( \\($namespace\\))]($style)\\]";
          };

          lua = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          memory_usage = {
            format = "\\[$symbol[$ram( | $swap)]($style)\\]";
          };

          meson = {
            format = "\\[[$symbol$project]($style)\\]";
          };

          nim = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          nix_shell = {
            format = "\\[[$symbol$state( \\($name\\))]($style)\\]";
          };

          nodejs = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          ocaml = {
            format = "\\[[$symbol($version)(\\($switch_indicator$switch_name\\))]($style)\\]";
          };

          openstack = {
            format = "\\[[$symbol$cloud(\\($project\\))]($style)\\]";
          };

          package = {
            format = "\\[[$symbol$version]($style)\\]";
          };

          perl = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          php = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          pulumi = {
            format = "\\[[$symbol$stack]($style)\\]";
          };

          purescript = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          python = {
            format = "\\[[$symbol$pyenv_prefix($version)(\\($virtualenv\\))]($style)\\]";
          };

          raku = {
            format = "\\[[$symbol($version-$vm_version)]($style)\\]";
          };

          red = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          ruby = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          rust = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          scala = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          spack = {
            format = "\\[[$symbol$environment]($style)\\]";
          };

          sudo = {
            format = "\\[as $symbol]($style)\\]";
          };

          swift = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          terraform = {
            format = "\\[[$symbol$workspace]($style)\\]";
          };

          time = {
            disabled = false;
            format = "\\[[$time]($style)\\]";
            use_12hr = false;
            utc_time_offset = "local";
            time_format = "%T";
            time_range = "-";
          };

          username = {
            format = "\\[[$user]($style)\\]";
          };

          vagrant = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          vlang = {
            format = "\\[[$symbol($version)]($style)\\]";
          };

          zig = {
            format = "\\[[$symbol($version)]($style)\\]";
          };
        };
      };
    };
}
