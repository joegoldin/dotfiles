{ ... }:
{
  den.aspects.gh.homeManager =
    {
      pkgs,
      ...
    }:
    let
      # Stacked PRs (`gh stack`). Both nixos-26.05 and our nixpkgs-unstable pin
      # still ship 0.0.4, which predates the `merge` and `trunk` subcommands and
      # the async merge API they drive. The gh-stack skill documents the 0.1.0
      # surface, so pin 0.1.0 here rather than bumping the shared unstable input.
      # Drop this once our nixpkgs carries >=0.1.0 and use pkgs.gh-stack.
      gh-stack = pkgs.buildGoModule rec {
        pname = "gh-stack";
        version = "0.1.0";

        src = pkgs.fetchFromGitHub {
          owner = "github";
          repo = "gh-stack";
          tag = "v${version}";
          hash = "sha256-48JkOeqbvHlCZ2u3LnwJymw55xMQWLTPJLDbV44clGI=";
        };

        vendorHash = "sha256-0Xtr/MOpX4u5GnbRdNxKPA0GpSzi8PIbVc9MmP05De4=";

        ldflags = [
          "-s"
          "-w"
          "-X=github.com/github/gh-stack/cmd.Version=${version}"
        ];

        doCheck = false;

        meta = {
          description = "GitHub CLI extension to use stacked PRs";
          homepage = "https://github.github.com/gh-stack/";
          mainProgram = "gh-stack";
        };
      };

      gh-pr-review = pkgs.buildGoModule rec {
        pname = "gh-pr-review";
        version = "1.6.2";

        src = pkgs.fetchFromGitHub {
          owner = "agynio";
          repo = "gh-pr-review";
          rev = "v${version}";
          hash = "sha256-NVctUkxfYGs29T9naAfqbEhUXfhynx8Ajsh+V+4gCLw=";
        };

        vendorHash = "sha256-CEV23koYz0FpSWXJRF4J+dGNuDT8Ftkn4LGFftvd0ts=";

        doCheck = false;

        meta = {
          description = "GitHub CLI extension for inline PR review comments";
          homepage = "https://github.com/agynio/gh-pr-review";
        };
      };
    in
    {
      programs.gh = {
        enable = true;
        extensions = [
          pkgs.gh-dash
          gh-pr-review
          gh-stack
        ];
      };
    };
}
