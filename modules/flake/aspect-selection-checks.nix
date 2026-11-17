{ inputs, lib, ... }:
{
  perSystem = { pkgs, ... }: {
    checks.aspect-selection =
      let
        # Inspect aspect contributions without the package-provider argument:
        # selecting an aspect must enable it, not probe an unrelated package.
        args = {
          inherit pkgs lib;
          customPackages = { };
          osConfig = { };
          config.home.homeDirectory = "/home/test";
        };
        aspect = name: (import (../ai + "/${name}.nix") { inherit inputs; }).den.aspects.${name};
        pi = (aspect "pi").homeManager args;
        claude = (aspect "claude").homeManager args;
        codex = (aspect "codex").homeManager args;
        antigravity = (aspect "antigravity").homeManager args;
        vllm = aspect "vllm";
      in
      assert !(vllm ? nixos);
      assert builtins.isList (vllm.homeManager args).home.packages;
      assert builtins.length (vllm.homeManager args).home.packages == 1;
      assert pi.programs.pi.coding-agent.enable;
      assert claude.programs.claude-nix.enable;
      assert codex.programs.codex-nix.enable;
      assert antigravity.programs.antigravity-cli-nix.enable;
      pkgs.runCommand "aspect-selection-tests" { } ''
        touch "$out"
      '';
  };
}
