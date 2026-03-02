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

  # ── Param helpers ─────────────────────────────────────────────────
  hasParams = s: s ? params && s.params != [ ];
  hasFlags = s: s ? flags && s.flags != [ ];

  getUsage =
    s:
    let
      flagStr =
        if hasFlags s then
          builtins.concatStringsSep " " (
            map (f: if f ? arg then "[${f.name} ${f.arg}]" else "[${f.name}]") s.flags
          )
        else
          "";
      paramStr =
        if hasParams s then
          builtins.concatStringsSep " " (
            map (p: if p.required or true then p.name else "[${p.name}]") s.params
          )
        else
          "";
      parts = builtins.filter (x: x != "") [
        flagStr
        paramStr
      ];
    in
    if hasParams s || hasFlags s then "${s.name} ${builtins.concatStringsSep " " parts}" else s.usage;

  hasRequiredParams = s: hasParams s && builtins.any (p: p.required or true) s.params;

  fishParamHelp =
    s:
    let
      argLines =
        if hasParams s then
          let
            lines = map (p: "    printf '  %-14s %s\\n' '${p.name}' '${p.desc}'") s.params;
          in
          ''
              echo ""
              echo "Arguments:"
            ${builtins.concatStringsSep "\n" lines}''
        else
          "";
      flagLines =
        if hasFlags s then
          let
            lines = map (
              f:
              let
                label = if f ? arg then "${f.name} ${f.arg}" else f.name;
              in
              "    printf '  %-14s %s\\n' '${label}' '${f.desc}'"
            ) s.flags;
          in
          ''
              echo ""
              echo "Options:"
            ${builtins.concatStringsSep "\n" lines}''
        else
          "";
    in
    argLines + flagLines;

  # ── Builders ───────────────────────────────────────────────────────
  mkFishBin =
    s:
    let
      usage = getUsage s;
      helpCond =
        if hasRequiredParams s then
          "if contains -- --help $argv; or contains -- -h $argv; or test (count $argv) -eq 0"
        else
          "if contains -- --help $argv; or contains -- -h $argv";
      paramHelp = fishParamHelp s;
    in
    pkgs.writeTextFile {
      inherit (s) name;
      executable = true;
      destination = "/bin/${s.name}";
      text = ''
        #!/usr/bin/env fish

        ${helpCond}
          echo "${s.name} - ${s.desc}"
          echo ""
          echo "Usage: ${usage}"
        ${paramHelp}
          exit 0
        end

        ${s.body}
      '';
    };

  mkPythonBin =
    s:
    let
      usage = getUsage s;
      pythonArgHelp =
        if hasParams s then
          let
            lines = map (p: "        print(\"  %-14s %s\" % (\"${p.name}\", \"${p.desc}\"))") s.params;
          in
          ''
                  print()
                  print("Arguments:")
            ${builtins.concatStringsSep "\n" lines}''
        else
          "";
      pythonFlagHelp =
        if hasFlags s then
          let
            lines = map (
              f:
              let
                label = if f ? arg then "${f.name} ${f.arg}" else f.name;
              in
              "        print(\"  %-14s %s\" % (\"${label}\", \"${f.desc}\"))"
            ) s.flags;
          in
          ''
                  print()
                  print("Options:")
            ${builtins.concatStringsSep "\n" lines}''
        else
          "";
      pythonParamHelp = pythonArgHelp + pythonFlagHelp;
      helpCond =
        if hasRequiredParams s then
          "if \"--help\" in sys.argv or \"-h\" in sys.argv or len(sys.argv) < 2:"
        else
          "if \"--help\" in sys.argv or \"-h\" in sys.argv:";
    in
    pkgs.writeTextFile {
      inherit (s) name;
      executable = true;
      destination = "/bin/${s.name}";
      text = ''
        #!${pkgs.python3}/bin/python3
        import sys
        ${helpCond}
            print("${s.name} - ${s.desc}")
            print()
            print("Usage: ${usage}")
        ${pythonParamHelp}
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
  mkCompletion =
    s:
    let
      helpLine = "complete -c ${s.name} -f -l help -s h -d \"Show help\"";
      paramLines =
        if hasParams s then
          builtins.concatStringsSep "\n" (
            builtins.filter (l: l != "") (
              map (
                p:
                if p ? completions && p.completions != "" then
                  "complete -c ${s.name} -f -a '(${p.completions})'"
                else
                  ""
              ) s.params
            )
          )
        else
          "";
      flagLines =
        if hasFlags s then
          builtins.concatStringsSep "\n" (
            map (
              f:
              let
                longName = builtins.replaceStrings [ "--" ] [ "" ] f.name;
                requiresArg = if f ? arg then " -r" else "";
              in
              "complete -c ${s.name} -l ${longName}${requiresArg} -d \"${f.desc}\""
            ) s.flags
          )
        else
          "";
      extra = builtins.filter (x: x != "") [
        paramLines
        flagLines
      ];
    in
    {
      "fish/completions/${s.name}.fish".text =
        helpLine + (if extra != [ ] then "\n${builtins.concatStringsSep "\n" extra}" else "") + "\n";
    };

  binsCompletion = {
    "fish/completions/bins.fish".text = ''
      complete -c bins -f -l help -s h -d "Show help"
    '';
  };

  allCompletions =
    (builtins.foldl' (acc: s: acc // mkCompletion s) { } (builtins.filter isBin scripts))
    // binsCompletion;

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
