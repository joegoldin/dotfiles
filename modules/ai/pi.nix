# pi (pi-nix) + the agent-skills library. The fourth first-class agent
# alongside Claude Code, Codex, and Antigravity.
{ inputs, ... }:
{
  den.aspects.pi.homeManager =
    {
      pkgs,
      lib,
      ...
    }:
    let
      # The same guard the sibling AI aspects use. pi's package comes from
      # pi-nix (re-exported through agent-skills) rather than the llm-agents
      # overlay, so this is not a hard dependency; it is this repo's marker
      # for "this host carries the AI toolchain", and keeping the condition
      # identical means all four agents switch on and off together.
      enabled = pkgs ? llm-agents;

      # jail.nix is bubblewrap, so linux only. pi-nix throws outright rather
      # than degrading if the flag is set on darwin, and torrent gets this
      # aspect.
      jailed = pkgs.stdenv.hostPlatform.isLinux;
    in
    {
      imports = [ inputs.agent-skills.homeManagerModules.pi ];

      programs.pi.coding-agent = lib.mkIf enabled {
        enable = true;

        jail.enable = jailed;
      };
    };
}
