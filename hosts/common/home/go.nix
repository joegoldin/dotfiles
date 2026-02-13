{
  pkgs,
  lib,
  ...
}: {
  packages = {
    claude-squad = pkgs.buildGoModule rec {
      pname = "claude-squad";
      version = "1.0.15-joe";

      src = pkgs.fetchFromGitHub {
        owner = "joegoldin";
        repo = "claude-squad";
        rev = "v${version}";
        hash = "sha256-/X12CBL0yCSvGrueZ2fnFOdLRVXKx2bqjsQhdevvmUM=";
      };

      vendorHash = "sha256-/mRyrcbQJpvX1aQttWSsRygcXqZCjJP0iIv9TWji8C8=";

      # Tests require git in PATH and a full git environment
      doCheck = false;

      # Runtime dependencies - claude-squad requires tmux for sessions and gh for GitHub operations
      nativeBuildInputs = [pkgs.makeWrapper];

      postInstall = ''
        wrapProgram $out/bin/claude-squad \
          --prefix PATH : ${lib.makeBinPath [pkgs.tmux pkgs.gh pkgs.git]}
      '';

      meta = with lib; {
        description = "Manage multiple AI terminal agents like Claude Code, Aider, Codex across separate workspaces";
        homepage = "https://github.com/joegoldin/claude-squad";
        license = licenses.agpl3Only;
        mainProgram = "claude-squad";
      };
    };
  };
}
