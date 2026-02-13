{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  jq,
  libnotify,
  terminal-notifier,
}:

stdenv.mkDerivation rec {
  pname = "code-notify";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "mylee04";
    repo = "code-notify";
    rev = "v${version}";
    hash = "sha256-fTgvzWKB6NbfD6S7E1gsbOwg9ny6+1gcIPPlT2X+ubg=";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ jq ]
    ++ lib.optionals stdenv.isLinux [ libnotify ]
    ++ lib.optionals stdenv.isDarwin [ terminal-notifier ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    # lib/ contains code-notify/ subdirectory, copy as-is
    cp -r lib $out/
    cp bin/code-notify $out/bin/

    # Fix LIB_DIR path in the script
    substituteInPlace $out/bin/code-notify \
      --replace 'LIB_DIR="$(dirname "$SCRIPT_DIR")/lib/code-notify"' \
                "LIB_DIR=\"$out/lib/code-notify\""

    chmod +x $out/bin/code-notify

    wrapProgram $out/bin/code-notify \
      --prefix PATH : ${lib.makeBinPath ([ jq ]
        ++ lib.optionals stdenv.isLinux [ libnotify ]
        ++ lib.optionals stdenv.isDarwin [ terminal-notifier ])}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Desktop notifications for Claude Code, Codex, and Gemini CLI";
    homepage = "https://github.com/mylee04/code-notify";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "code-notify";
  };
}
