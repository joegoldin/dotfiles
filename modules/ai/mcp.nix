# System-wide MCP servers, declared once and fanned out by the
# agent-skills module to Claude, Antigravity, and Codex.
{ ... }:
{
  den.aspects.mcp.homeManager =
    {
      pkgs,
      lib,
      ...
    }:
    {
      programs.agent-skills.mcpServers = lib.mkIf (pkgs ? mcp-nixos) {
        # ── Examples (uncomment + configure) ─────────────────────────────
        #
        # Zero-config NixOS/nixpkgs knowledge server. Commented out because the
        # agent-skills nix-helper skill already ships it plugin-scoped for
        # claude/codex — enabling it here would run a duplicate for Claude.
        # nixos.command = lib.getExe' pkgs.mcp-nixos "mcp-nixos";
        #
        # GitHub MCP — needs a token. Reference an env var, never a raw secret.
        # github = {
        #   command = lib.getExe' pkgs.github-mcp-server "github-mcp-server";
        #   env.GITHUB_PERSONAL_ACCESS_TOKEN = "$GITHUB_TOKEN";
        # };
        #
        # Language-server MCP — needs per-language args.
        # language-server = {
        #   command = lib.getExe' pkgs.mcp-language-server "mcp-language-server";
        #   args = [ "--workspace" "%WORKSPACE%" "--lsp" "gopls" ];
        # };
        #
        # stdio example via npx (no package needed):
        # context7 = { command = "npx"; args = [ "-y" "@upstash/context7-mcp" ]; };
        #
        # Remote (HTTP) example — claude/antigravity use headers, codex uses
        # bearerTokenEnvVar; set whichever your agents need:
        # figma = { url = "https://mcp.figma.com/mcp"; bearerTokenEnvVar = "FIGMA_OAUTH_TOKEN"; };
      };
    };
}
