{ pkgs, ... }:
let
  # ── Import all script definitions from ./scripts/ ──────────────────
  scriptFiles = builtins.attrNames (builtins.readDir ./scripts);
  scripts = builtins.sort (a: b: a.name < b.name) (map (f: import (./scripts + "/${f}")) scriptFiles);

  # ── Type predicates ────────────────────────────────────────────────
  isFishBin = s: s.type == "fish";
  isPythonBin = s: s.type == "python";
  isPythonArgparse = s: s.type == "python-argparse";
  isFunction = s: s.type == "function";
  isBin = s: isFishBin s || isPythonBin s || isPythonArgparse s;

  # ── Builders ───────────────────────────────────────────────────────
  mkFishBin =
    s:
    pkgs.writeTextFile {
      inherit (s) name;
      executable = true;
      destination = "/bin/${s.name}";
      text = ''
        #!/usr/bin/env fish

        if contains -- --help $argv; or contains -- -h $argv
          echo "${s.name} - ${s.desc}"
          echo ""
          echo "Usage: ${s.usage}"
          exit 0
        end

        ${s.body}
      '';
    };

  mkPythonBin =
    s:
    pkgs.writeTextFile {
      inherit (s) name;
      executable = true;
      destination = "/bin/${s.name}";
      text = ''
        #!${pkgs.python3}/bin/python3
        import sys
        if "--help" in sys.argv or "-h" in sys.argv:
            print("${s.name} - ${s.desc}")
            print()
            print("Usage: ${s.usage}")
            sys.exit(0)

        ${s.body}
      '';
    };

  mkPythonArgparseBin =
    s:
    pkgs.writeTextFile {
      inherit (s) name;
      executable = true;
      destination = "/bin/${s.name}";
      text = ''
        #!${pkgs.python3}/bin/python3
        ${s.body}
      '';
    };

  mkBin =
    s:
    if isFishBin s then
      mkFishBin s
    else if isPythonBin s then
      mkPythonBin s
    else
      mkPythonArgparseBin s;

  # ── Derivations ────────────────────────────────────────────────────
  binScripts = builtins.filter isBin scripts;
  functionScripts = builtins.filter isFunction scripts;
  scriptDerivations = map mkBin binScripts;

  # ── bins command ───────────────────────────────────────────────────
  binsLines = builtins.concatStringsSep "\n" (
    map (s: "  printf '  %-12s %s\\n' '${s.name}' '${s.desc}'") scripts
  );

  binsScript = pkgs.writeTextFile {
    name = "bins";
    executable = true;
    destination = "/bin/bins";
    text = ''
      #!/usr/bin/env fish

      if contains -- --help $argv; or contains -- -h $argv
        echo "bins - List all custom scripts"
        echo ""
        echo "Usage: bins"
        exit 0
      end

      ${binsLines}
    '';
  };

  # ── Fish completions ───────────────────────────────────────────────
  mkCompletion = s: {
    "fish/completions/${s.name}.fish".text = ''
      complete -c ${s.name} -f -l help -s h -d "Show help"
    '';
  };

  specialCompletions = {
    "fish/completions/snippets.fish".text = ''
      complete -c snippets -f -l help -s h -d "Show help"
      complete -c snippets -f -a '(ls $HOME/dotfiles/snippets/ 2>/dev/null)'
    '';
    "fish/completions/sfx.fish".text = ''
      complete -c sfx -f -l help -s h -d "Show help"
      complete -c sfx -f -a '(ls $HOME/dotfiles/assets/sfx/ 2>/dev/null | string replace -r "\\.ogg\$" "")'
    '';
    "fish/completions/bins.fish".text = ''
      complete -c bins -f -l help -s h -d "Show help"
    '';
  };

  specialNames = [
    "snippets"
    "sfx"
  ];
  basicCompletions = builtins.foldl' (acc: s: acc // mkCompletion s) { } (
    builtins.filter (s: !(builtins.elem s.name specialNames) && isBin s) scripts
  );

  allCompletions = basicCompletions // specialCompletions;

in
{
  home.packages = scriptDerivations ++ [ binsScript ];

  programs.fish.functions = builtins.listToAttrs (
    map (s: {
      name = s.name;
      value = s.body;
    }) functionScripts
  );

  xdg.configFile = allCompletions;
}
