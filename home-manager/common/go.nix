{
  pkgs,
  lib,
  ...
}: {
  packages = {
    claude-squad = pkgs.buildGoModule rec {
      pname = "claude-squad";
      version = "1.0.14";

      src = pkgs.fetchFromGitHub {
        owner = "smtg-ai";
        repo = "claude-squad";
        rev = "v${version}";
        hash = "sha256-zh4vhZMtKbNT3MxNr18Q/3XC0AecFf5tOYIRT1aFk38=";
      };

      vendorHash = "sha256-BduH6Vu+p5iFe1N5svZRsb9QuFlhf7usBjMsOtRn2nQ=";

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
        homepage = "https://github.com/smtg-ai/claude-squad";
        license = licenses.mit;
        mainProgram = "claude-squad";
      };
    };
  };
}
