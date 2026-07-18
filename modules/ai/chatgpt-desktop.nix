# ChatGPT Desktop (chatgpt-desktop-linux). Linux-only Electron repack of the
# official macOS app — include this aspect on graphical Linux hosts only;
# macOS hosts get the official apps via the chatgpt/codex-app Homebrew casks.
{ inputs, ... }:
{
  den.aspects.chatgpt-desktop.homeManager =
    { pkgs, lib, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      # OpenAI ships several desktop builds a day against the unversioned
      # ChatGPT.dmg URL, so the flake's DMG pin goes stale fast (three builds
      # on 2026-07-09 alone). Re-pin hash+version here — verified against
      # https://persistent.oaistatic.com/codex-app-prod/ChatGPT.dmg and its
      # appcast — and refresh both replacements together when a build starts
      # failing with a ChatGPT.dmg hash mismatch:
      #   nix hash file --sri --type sha256 <freshly downloaded ChatGPT.dmg>
      patchedSrc = pkgs.applyPatches {
        name = "chatgpt-desktop-linux-repinned";
        src = inputs.chatgpt-desktop-linux;
        postPatch = ''
          substituteInPlace flake.nix \
            --replace-fail "sha256-TukDFPYFaGI+WE63hQuBc3d307761tMCi9+oco6sImU=" \
                           "sha256-xgK3kJYGqI3M5ZbZGlRCjcO1MFo/Ee+MMGDZ/tw6E5Y=" \
            --replace-fail "26.707.30751" "26.715.31925"
        '';
      };
      # Re-instantiate the patched flake; its only inputs are nixpkgs and
      # flake-utils (already follows-wired), and its self references all have
      # `or` fallbacks, so a fix-point over the outputs is sufficient.
      chatgptFlake =
        let
          result = (import "${patchedSrc}/flake.nix").outputs {
            self = result // {
              outPath = patchedSrc;
            };
            inherit (inputs) nixpkgs flake-utils;
          };
        in
        result;
    in
    {
      imports = [ inputs.chatgpt-desktop-linux.homeManagerModules.default ];

      programs.chatgptDesktopLinux = {
        enable = true;
        package = chatgptFlake.packages.${system}.chatgpt-desktop;
        # Bake CODEX_CLI_PATH into the launcher so the app finds the codex CLI
        # even when the graphical session doesn't have the profile on PATH.
        cliPackage = lib.mkIf (pkgs ? llm-agents) pkgs.llm-agents.codex;
      };
    };
}
