{ pkgs, ... }:
let
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
    ];
  };
}
