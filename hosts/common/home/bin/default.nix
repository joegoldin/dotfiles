{ pkgs, ... }:
let
  # ── Import all script definitions from ./scripts/ ──────────────────
  scriptFiles = builtins.attrNames (builtins.readDir ./scripts);
  scripts = builtins.sort (a: b: a.name < b.name) (
    map (
      f:
      let
        raw = import (./scripts + "/${f}");
      in
      if builtins.isFunction raw then raw { inherit pkgs; } else raw
    ) scriptFiles
  );

  # ── Flag helpers ─────────────────────────────────────────────────────
  lib = pkgs.lib;

  # Strip -- prefix, convert - to _ for variable names
  normalizeFlagName = name: builtins.replaceStrings [ "-" ] [ "_" ] (lib.removePrefix "--" name);

  # Generate env var name: POG_<UPPER> unless overridden
  flagEnvVar = f: if f ? envVar then f.envVar else "POG_${lib.toUpper (normalizeFlagName f.name)}";

  # Extract short flag letter (strip - prefix)
  flagShort =
    f:
    if f ? short then
      lib.removePrefix "-" f.short
    else
      builtins.substring 0 1 (normalizeFlagName f.name);

  # Is this a bool flag?
  flagIsBool = f: f.bool or false;

  # Default value
  flagDefault = f: f.default or "";

  # Is this flag required?
  flagRequired = f: f.required or false;

  # Argument placeholder
  flagArg = f: f.arg or "VAR";

  # Generate PATH from runtimeInputs
  mkRuntimePath = inputs: lib.makeBinPath inputs;

  # Does this script use enhanced features?
  hasEnhancedFeatures =
    s:
    hasFlags s
    || (s ? runtimeInputs && s.runtimeInputs != [ ])
    || (s ? beforeExit && s.beforeExit != "");

  # ── Type predicates ────────────────────────────────────────────────
  isFishBin = s: s.type == "fish";
  isPythonBin = s: s.type == "python";
  isPythonArgparse = s: s.type == "python-argparse";
  isBashBin = s: s.type == "bash";
  isFunction = s: s.type == "function";
  isBin = s: isFishBin s || isPythonBin s || isPythonArgparse s || isBashBin s;

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

  # ── Bash preamble generators ──────────────────────────────────────

  # Auto-added flags for every bash script
  bashAutoFlags = [
    {
      name = "--verbose";
      short = "-v";
      desc = "Enable verbose output";
      bool = true;
      default = "";
    }
    {
      name = "--help";
      short = "-h";
      desc = "Show this help message";
      bool = true;
      default = "";
    }
  ];

  # All flags including auto-added ones
  bashAllFlags =
    s:
    let
      userFlags = if hasFlags s then s.flags else [ ];
      userFlagNames = map (f: f.name) userFlags;
      # Only add auto flags that the user hasn't already defined
      autoToAdd = builtins.filter (af: !(builtins.elem af.name userFlagNames)) bashAutoFlags;
    in
    userFlags ++ autoToAdd;

  # Terminal color detection and ANSI variable setup
  bashColorSetup = ''
    _setup_colors() {
      if [[ -t 2 ]] && [[ -z "''${NO_COLOR:-}" ]] && [[ "''${TERM:-}" != "dumb" ]]; then
        RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[0;33m' BLUE=$'\033[0;34m'
        BOLD=$'\033[1m' RESET=$'\033[0m'
      else
        RED="" GREEN="" YELLOW="" BLUE="" BOLD="" RESET=""
      fi
    }
    _setup_colors
  '';

  # Helper functions: die, debug, green, red, yellow, blue, bold
  bashHelpers = ''
    die() { echo "''${RED}error: $*''${RESET}" >&2; exit 1; }
    debug() { if [[ -n "''${verbose:-}" ]]; then echo "''${BLUE}debug: $*''${RESET}" >&2; fi; }
    green() { echo "''${GREEN}$*''${RESET}"; }
    red() { echo "''${RED}$*''${RESET}"; }
    yellow() { echo "''${YELLOW}$*''${RESET}"; }
    blue() { echo "''${BLUE}$*''${RESET}"; }
    bold() { echo "''${BOLD}$*''${RESET}"; }
  '';

  # Generate flag default assignments with env var overrides
  bashFlagDefaults =
    s:
    let
      flags = bashAllFlags s;
      mkDefault =
        f:
        let
          varName = normalizeFlagName f.name;
          envVar = flagEnvVar f;
          defVal = flagDefault f;
        in
        "${varName}=\"" + "$" + "{${envVar}:-${defVal}}\"";
    in
    builtins.concatStringsSep "\n" (map mkDefault flags);

  # Generate usage() function from name/desc/flags/params
  bashUsage =
    s:
    let
      flags = bashAllFlags s;
      params = if hasParams s then s.params else [ ];
      flagStr =
        if flags != [ ] then
          builtins.concatStringsSep " " (
            map (f: if flagIsBool f then "[${f.name}]" else "[${f.name} ${flagArg f}]") flags
          )
        else
          "";
      paramStr =
        if params != [ ] then
          builtins.concatStringsSep " " (map (p: if p.required or true then p.name else "[${p.name}]") params)
        else
          "";
      usageParts = builtins.filter (x: x != "") [
        flagStr
        paramStr
      ];
      usageLine = "${s.name} ${builtins.concatStringsSep " " usageParts}";

      # Build param help lines
      paramHelpLines =
        if params != [ ] then
          [
            "  echo \"\""
            "  echo \"Arguments:\""
          ]
          ++ (map (p: "  printf '  %-20s %s\\n' '${p.name}' '${p.desc}'") params)
        else
          [ ];

      # Build flag help lines
      flagHelpLines =
        if flags != [ ] then
          [
            "  echo \"\""
            "  echo \"Options:\""
          ]
          ++ (map (
            f:
            let
              shortStr = "-${flagShort f}";
              longStr = if flagIsBool f then f.name else "${f.name} ${flagArg f}";
              label = "${shortStr}, ${longStr}";
            in
            "  printf '  %-20s %s\\n' '${label}' '${f.desc}'"
          ) flags)
        else
          [ ];

      allHelpLines = paramHelpLines ++ flagHelpLines;
    in
    ''
      usage() {
        echo "''${BOLD}${s.name}''${RESET} - ${s.desc}"
        echo ""
        echo "Usage: ${usageLine}"
      ${builtins.concatStringsSep "\n" allHelpLines}
        exit 0
      }
    '';

  # Generate getopt-based flag parsing loop
  bashGetopt =
    s:
    let
      flags = bashAllFlags s;

      # Build short opts string: e.g. "vhd:"
      shortOpts = builtins.concatStringsSep "" (
        map (
          f:
          let
            short = flagShort f;
            suffix = if flagIsBool f then "" else ":";
          in
          "${short}${suffix}"
        ) flags
      );

      # Build long opts string: e.g. "verbose,help,dry-run:"
      longOpts = builtins.concatStringsSep "," (
        map (
          f:
          let
            long = lib.removePrefix "--" f.name;
            suffix = if flagIsBool f then "" else ":";
          in
          "${long}${suffix}"
        ) flags
      );

      # Build case entries
      caseEntries = builtins.concatStringsSep "\n" (
        map (
          f:
          let
            varName = normalizeFlagName f.name;
            short = "-${flagShort f}";
          in
          if f.name == "--help" then
            ''
              ${short}|${f.name})
                usage
                ;;''
          else if flagIsBool f then
            ''
              ${short}|${f.name})
                ${varName}="true"
                shift
                ;;''
          else
            ''
              ${short}|${f.name})
                ${varName}="$2"
                shift 2
                ;;''
        ) flags
      );
    in
    ''
      OPTS=$(getopt -o '${shortOpts}' -l '${longOpts}' -- "$@") || die "Failed to parse options"
      eval set -- "$OPTS"
      while true; do
        case "$1" in
      ${caseEntries}
          --)
            shift
            break
            ;;
          *)
            die "Unexpected option: $1"
            ;;
        esac
      done
    '';

  # Generate required flag validation checks
  bashRequiredValidation =
    s:
    let
      flags = if hasFlags s then s.flags else [ ];
      requiredFlags = builtins.filter flagRequired flags;
      checks = map (
        f:
        let
          varName = normalizeFlagName f.name;
        in
        "[[ -z \"" + "$" + "{${varName}}\" ]] && die \"Required option ${f.name} is missing\""
      ) requiredFlags;
    in
    builtins.concatStringsSep "\n" checks;

  # ── Fish preamble generators ──────────────────────────────────────
  fishHelpers = ''
    function die
      set_color red; echo "error: $argv[1]" >&2; set_color normal
      exit (test (count $argv) -ge 2; and echo $argv[2]; or echo 1)
    end
    function debug
      if set -q _flag_verbose
        set_color blue; echo "[debug] $argv" >&2; set_color normal
      end
    end
    function green; set_color green; echo $argv; set_color normal; end
    function red; set_color red; echo $argv; set_color normal; end
    function yellow; set_color yellow; echo $argv; set_color normal; end
    function blue; set_color blue; echo $argv; set_color normal; end
    function bold; set_color --bold; echo $argv; set_color normal; end
  '';

  fishArgparse =
    flags:
    let
      specs = map (
        f:
        let
          sh = flagShort f;
          longName = normalizeFlagName f.name;
          shPart = if sh != "" then "${sh}/" else "";
          valPart = if flagIsBool f then "" else "=";
        in
        "'${shPart}${longName}${valPart}'"
      ) flags;
    in
    "argparse 'h/help' 'v/verbose' ${builtins.concatStringsSep " " specs} -- $argv; or exit 1";

  fishEnvVarDefaults =
    flags:
    builtins.concatStringsSep "\n" (
      map (
        f:
        let
          varName = normalizeFlagName f.name;
          envName = flagEnvVar f;
          def = flagDefault f;
          hasDef = def != "";
        in
        ''
          if not set -q _flag_${varName}
            if set -q ${envName}; and test -n "$$envName"
              set _flag_${varName} $$envName
            ${lib.optionalString hasDef ''
              else
                          set _flag_${varName} "${def}"''}
            end
          end''
      ) flags
    );

  fishRequiredValidation =
    flags:
    builtins.concatStringsSep "\n" (
      builtins.filter (x: x != "") (
        map (
          f:
          if flagRequired f then
            let
              varName = normalizeFlagName f.name;
            in
            ''
              if not set -q _flag_${varName}; or test -z "$_flag_${varName}"
                die "required flag '${f.name}' not provided"
              end''
          else
            ""
        ) flags
      )
    );

  # ── Python preamble generators ──────────────────────────────────────
  pythonHelpers = ''
    import os as _os
    import sys as _sys
    import atexit as _atexit

    _NO_COLOR = not _sys.stderr.isatty() or _os.environ.get("NO_COLOR")
    RESET = "" if _NO_COLOR else "\033[0m"
    RED = "" if _NO_COLOR else "\033[0;31m"
    GREEN = "" if _NO_COLOR else "\033[0;32m"
    YELLOW = "" if _NO_COLOR else "\033[0;33m"
    BLUE = "" if _NO_COLOR else "\033[0;34m"
    BOLD = "" if _NO_COLOR else "\033[1m"

    def die(msg, code=1):
        print(f"{RED}error:{RESET} {msg}", file=_sys.stderr)
        _sys.exit(code)

    def debug(msg):
        if _args and _args.verbose:
            print(f"{BLUE}[debug]{RESET} {msg}", file=_sys.stderr)

    def green(msg): print(f"{GREEN}{msg}{RESET}")
    def red(msg): print(f"{RED}{msg}{RESET}")
    def yellow(msg): print(f"{YELLOW}{msg}{RESET}")
    def blue(msg): print(f"{BLUE}{msg}{RESET}")
    def bold(msg): print(f"{BOLD}{msg}{RESET}")

    _args = None
  '';

  pythonArgparse =
    s:
    let
      flags = s.flags or [ ];
      params = s.params or [ ];
      flagArgs = builtins.concatStringsSep "\n" (
        map (
          f:
          let
            varName = normalizeFlagName f.name;
            longFlag = "--${builtins.replaceStrings [ "_" ] [ "-" ] varName}";
            sh = flagShort f;
            shortStr = if sh != "" then ''"-${sh}", '' else "";
            envName = flagEnvVar f;
            def = flagDefault f;
          in
          if flagIsBool f then
            ''_parser.add_argument(${shortStr}"${longFlag}", action="store_true", default=bool(_os.environ.get("${envName}", "")), help="${f.desc or "a flag"}")''
          else
            let
              defExpr = if def != "" then ''"${def}"'' else "None";
            in
            ''_parser.add_argument(${shortStr}"${longFlag}", default=_os.environ.get("${envName}", "") or ${defExpr}, ${lib.optionalString (flagRequired f) ''required=not bool(_os.environ.get("${envName}", "")), ''}help="${f.desc or "a flag"}")''
        ) flags
      );
      paramArgs = builtins.concatStringsSep "\n" (
        map (
          p:
          let
            varName = lib.toLower (builtins.replaceStrings [ "-" " " ] [ "_" "_" ] p.name);
            nargs =
              if p ? nargs then
                p.nargs
              else if p.required or true then
                null
              else
                "?";
            nargsStr = if nargs != null then '', nargs="${nargs}"'' else "";
            def = if p ? default then '', default="${p.default}"'' else "";
          in
          ''_parser.add_argument("${varName}"${nargsStr}${def}, help="${p.desc}")''
        ) params
      );
    in
    ''
      import argparse as _argparse
      _parser = _argparse.ArgumentParser(prog="${s.name}", description="${s.desc}")
      _parser.add_argument("-v", "--verbose", action="store_true", default=bool(_os.environ.get("POG_VERBOSE", "")), help="show debug output")
      ${flagArgs}
      ${paramArgs}
      _args = _parser.parse_args()
      verbose = _args.verbose
    '';

  # ── Builders ───────────────────────────────────────────────────────
  mkFishBin =
    s:
    let
      usage = getUsage s;
      flags = s.flags or [ ];
      enhanced = hasEnhancedFeatures s;
      runtimePath = mkRuntimePath (s.runtimeInputs or [ ]);
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

        ${lib.optionalString (runtimePath != "") "set -gx PATH \"${runtimePath}\" $PATH"}

        ${lib.optionalString enhanced fishHelpers}

        ${helpCond}
          echo "${s.name} - ${s.desc}"
          echo ""
          echo "Usage: ${usage}"
        ${paramHelp}
        ${lib.optionalString enhanced ''
          echo ""
          echo "  -v, --verbose    Show debug output"
          echo "  -h, --help       Show this help"
        ''}
          exit 0
        end

        ${lib.optionalString (hasFlags s) (fishArgparse flags)}

        ${lib.optionalString (hasFlags s) (fishEnvVarDefaults flags)}

        ${lib.optionalString (hasFlags s) (fishRequiredValidation flags)}

        ${lib.optionalString (s ? beforeExit && s.beforeExit != "") ''
          function _cleanup --on-event fish_exit
            ${s.beforeExit}
          end
        ''}

        ${s.body}
      '';
    };

  mkPythonBin =
    s:
    let
      enhanced = hasEnhancedFeatures s || hasFlags s || hasParams s;
      runtimePath = mkRuntimePath (s.runtimeInputs or [ ]);
      pythonWithPkgs =
        if s ? pythonPackages && s.pythonPackages != [ ] then
          pkgs.python3.withPackages (ps: map (name: ps.${name}) s.pythonPackages)
        else
          pkgs.python3;
    in
    if enhanced then
      pkgs.writeTextFile {
        inherit (s) name;
        executable = true;
        destination = "/bin/${s.name}";
        text = ''
          #!${pythonWithPkgs}/bin/python3
          ${lib.optionalString (runtimePath != "") ''
            import os as _os_path
            _os_path.environ["PATH"] = "${runtimePath}:" + _os_path.environ.get("PATH", "")
          ''}

          ${pythonHelpers}

          ${pythonArgparse s}

          ${lib.optionalString (s ? beforeExit && s.beforeExit != "") ''
            def _cleanup():
                ${s.beforeExit}
            _atexit.register(_cleanup)
          ''}

          ${s.body}
        '';
      }
    else
      # Legacy path - identical to current behavior
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
          #!${pythonWithPkgs}/bin/python3
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

  mkBashBin =
    s:
    let
      strict = s.strict or true;
      autoparse = s.autoparse or true;
      runtimeInputs = s.runtimeInputs or [ ];
      beforeExit = s.beforeExit or "";

      # Strict mode
      strictLine = lib.optionalString strict "set -o errexit -o pipefail -o nounset";

      # PATH setup
      pathLine = lib.optionalString (
        runtimeInputs != [ ]
      ) "export PATH=\"${mkRuntimePath runtimeInputs}:$PATH\"";

      # Flag defaults
      defaults = bashFlagDefaults s;

      # Usage function
      usage = bashUsage s;

      # getopt parsing (only if autoparse is true)
      getopt = lib.optionalString autoparse (bashGetopt s);

      # Required validation (only if autoparse is true)
      validation = lib.optionalString autoparse (bashRequiredValidation s);

      # Cleanup trap
      cleanupSection = lib.optionalString (beforeExit != "") ''
        _cleanup() {
          ${beforeExit}
        }
        trap _cleanup EXIT
      '';
    in
    pkgs.writeTextFile {
      inherit (s) name;
      executable = true;
      destination = "/bin/${s.name}";
      text = ''
        #!/usr/bin/env bash
        ${strictLine}
        ${pathLine}

        ${bashColorSetup}

        ${bashHelpers}

        ${defaults}

        ${usage}

        ${getopt}

        ${validation}

        ${cleanupSection}

        ${s.body}
      '';
    };

  mkBin =
    s:
    if isFishBin s then
      mkFishBin s
    else if isPythonBin s then
      mkPythonBin s
    else if isBashBin s then
      mkBashBin s
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
      verboseLine = lib.optionalString (hasEnhancedFeatures s) "\ncomplete -c ${s.name} -f -l verbose -s v -d \"Show debug output\"";
      paramLines =
        if hasParams s then
          builtins.concatStringsSep "\n" (
            builtins.filter (l: l != "") (
              map (
                p:
                if p ? completions && p.completions != "" then
                  let
                    escaped = builtins.replaceStrings [ "'" ] [ "'\\''" ] p.completions;
                  in
                  "complete -c ${s.name} -f -a '(${escaped})'"
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
                longName = normalizeFlagName f.name;
                sh = flagShort f;
                shortPart = if sh != "" then " -s ${sh}" else "";
                requiresArg = if !(flagIsBool f) then " -r" else "";
                escapedCompletion = builtins.replaceStrings [ "'" ] [ "'\\''" ] (f.completion or "");
                completionPart =
                  if f ? completion && f.completion != "" then " -a '(${escapedCompletion})'" else "";
              in
              "complete -c ${s.name} -l ${longName}${shortPart}${requiresArg}${completionPart} -d \"${f.desc or "a flag"}\""
            ) (s.flags or [ ])
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
        helpLine
        + verboseLine
        + (if extra != [ ] then "\n${builtins.concatStringsSep "\n" extra}" else "")
        + "\n";
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
