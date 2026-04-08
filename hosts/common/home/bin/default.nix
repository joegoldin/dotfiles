{ pkgs, ... }:
let
  # ── Import all script definitions from ./scripts/ ──────────────────
  scriptDir = builtins.readDir ./scripts;
  scriptFiles = builtins.filter (f: scriptDir.${f} == "regular") (builtins.attrNames scriptDir);
  scripts = builtins.sort (a: b: a.name < b.name) (
    map (
      f:
      let
        raw = import (./scripts + "/${f}");
        resolved = if builtins.isFunction raw then raw { inherit pkgs; } else raw;
      in
      normalizeScript resolved
    ) scriptFiles
  );

  # ── Import subcommand groups from subdirectories ───────────────────
  subcommandDirs = builtins.filter (f: scriptDir.${f} == "directory") (builtins.attrNames scriptDir);
  subcommandGroups = map (
    dir:
    let
      subFiles = builtins.attrNames (builtins.readDir (./scripts + "/${dir}"));
      subs = builtins.sort (a: b: a.name < b.name) (
        map (
          f:
          let
            raw = import (./scripts + "/${dir}/${f}");
            resolved = if builtins.isFunction raw then raw { inherit pkgs; } else raw;
          in
          normalizeScript resolved
        ) subFiles
      );
    in
    {
      name = dir;
      inherit subs;
    }
  ) subcommandDirs;

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

  # Resolve short flags for all flags in a script, auto-uppercasing on collision.
  # Returns the flags list with `short` explicitly set on each.
  resolveShorts =
    scriptName: flags:
    let
      # Reserved shorts from auto-added flags
      reserved = [ "h" "v" ];

      resolve = acc: remaining:
        if remaining == [ ] then
          acc.resolved
        else
          let
            f = builtins.head remaining;
            rest = builtins.tail remaining;
            candidate =
              if f ? short then
                lib.removePrefix "-" f.short
              else
                builtins.substring 0 1 (normalizeFlagName f.name);
            lower = lib.toLower candidate;
            upper = lib.toUpper candidate;
            chosen =
              if !(builtins.elem candidate acc.taken) then candidate
              else if candidate == lower && !(builtins.elem upper acc.taken) then upper
              else if candidate == upper && !(builtins.elem lower acc.taken) then lower
              else builtins.throw "Script '${scriptName}': short flag collision for '${f.name}' (-${candidate}), both -${lower} and -${upper} are taken";
          in
          resolve {
            taken = acc.taken ++ [ chosen ];
            resolved = acc.resolved ++ [ (f // { short = "-${chosen}"; }) ];
          } rest;
    in
    resolve { taken = reserved; resolved = []; } flags;

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

  # ── String escaping helpers ───────────────────────────────────────
  # Escape for single-quoted shell contexts: ' -> '\''
  escSQ = s: builtins.replaceStrings [ "'" ] [ "'\\''" ] s;
  # Escape for fish double-quoted contexts: \ $ "
  escFishDQ = s: builtins.replaceStrings [ "\\" "$" "\"" ] [ "\\\\" "\\$" "\\\"" ] s;
  # Escape for bash double-quoted contexts: \ $ " `
  escBashDQ = s: builtins.replaceStrings [ "\\" "$" "\"" "`" ] [ "\\\\" "\\$" "\\\"" "\\`" ] s;
  # Escape for Python string literals: \ "
  escPyStr = s: builtins.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ] s;

  # ── Script normalization ──────────────────────────────────────────
  # Derive type and body from language-named fields (fish, bash, python, etc.)
  # Resolve short flag collisions (auto-uppercase on conflict, error if both taken)
  # Falls back to explicit type + body for backwards compatibility
  normalizeScript =
    s:
    let
      base =
        if s ? fish then
          s // { type = "fish"; body = s.fish; }
        else if s ? bash then
          s // { type = "bash"; body = s.bash; }
        else if s ? python then
          s // { type = "python"; body = s.python; }
        else if s ? python-argparse then
          s // { type = "python-argparse"; body = s.python-argparse; }
        else if s ? function then
          s // { type = "function"; body = s.function; }
        else
          s;
      name = base.name or "unknown";
    in
    if base ? flags && base.flags != [ ] then
      base // { flags = resolveShorts name base.flags; }
    else
      base;

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
  hasExamples = s: s ? examples && s.examples != [ ];

  # Display name for help text (defaults to s.name, can be overridden for subcommands)
  getDisplayName = s: s.displayName or s.name;

  getUsage =
    s:
    let
      dn = getDisplayName s;
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
    if hasParams s || hasFlags s then "${dn} ${builtins.concatStringsSep " " parts}" else s.usage or "${dn} [args...]";

  hasRequiredParams = s: hasParams s && builtins.any (p: p.required or true) s.params;

  fishParamHelp =
    s:
    let
      argLines =
        if hasParams s then
          let
            lines = map (p: "    printf '  %-14s %s\\n' '${escSQ p.name}' '${escSQ p.desc}'") s.params;
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
              "    printf '  %-14s %s\\n' '${escSQ label}' '${escSQ f.desc}'"
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

  # ── Example helpers ─────────────────────────────────────────────
  fishExamplesHelp =
    s:
    if hasExamples s then
      let
        lines = map (e: "    printf '  %-30s %s\\n' '${escSQ e.cmd}' '${escSQ e.desc}'") s.examples;
      in
      ''
          echo ""
          echo "Examples:"
        ${builtins.concatStringsSep "\n" lines}''
    else
      "";

  bashExamplesHelp =
    s:
    if hasExamples s then
      [
        "  echo \"\""
        "  echo \"Examples:\""
      ]
      ++ (map (e: "  printf '  %-30s %s\\n' '${escSQ e.cmd}' '${escSQ e.desc}'") s.examples)
    else
      [ ];

  pythonExamplesHelp =
    s:
    if hasExamples s then
      let
        lines = map (
          e: "        print(\"  %-30s %s\" % (\"${escPyStr e.cmd}\", \"${escPyStr e.desc}\"))"
        ) s.examples;
      in
      "        print()\n        print(\"Examples:\")\n" + builtins.concatStringsSep "\n" lines
    else
      "";

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
        "${varName}=\"" + "$" + "{${envVar}:-${escBashDQ defVal}}\"";
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
      dn = getDisplayName s;
      usageLine = "${dn} ${builtins.concatStringsSep " " usageParts}";

      # Build param help lines
      paramHelpLines =
        if params != [ ] then
          [
            "  echo \"\""
            "  echo \"Arguments:\""
          ]
          ++ (map (p: "  printf '  %-20s %s\\n' '${escSQ p.name}' '${escSQ p.desc}'") params)
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
            "  printf '  %-20s %s\\n' '${escSQ label}' '${escSQ f.desc}'"
          ) flags)
        else
          [ ];

      examplesHelpLines = bashExamplesHelp s;
      allHelpLines = paramHelpLines ++ flagHelpLines ++ examplesHelpLines;
    in
    ''
      usage() {
        echo "''${BOLD}${escBashDQ dn}''${RESET} - ${escBashDQ s.desc}"
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
        "[[ -z \"" + "$" + "{${varName}}\" ]] && die \"Required option ${escBashDQ f.name} is missing\""
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
    s: flags:
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
      passthrough = s.passthrough or false;
      opts = lib.optionalString passthrough "--ignore-unknown ";
    in
    "argparse ${opts}'h/help' 'v/verbose' ${builtins.concatStringsSep " " specs} -- $argv; or exit 1";

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
                          set _flag_${varName} "${escFishDQ def}"''}
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
                die "required flag '${escFishDQ f.name}' not provided"
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
            ''_parser.add_argument(${shortStr}"${longFlag}", action="store_true", default=bool(_os.environ.get("${envName}", "")), help="${escPyStr (f.desc or "a flag")}")''
          else
            let
              defExpr = if def != "" then ''"${escPyStr def}"'' else "None";
            in
            ''_parser.add_argument(${shortStr}"${longFlag}", default=_os.environ.get("${envName}", "") or ${defExpr}, ${lib.optionalString (flagRequired f) ''required=not bool(_os.environ.get("${envName}", "")), ''}help="${escPyStr (f.desc or "a flag")}")''
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
            def = if p ? default then '', default="${escPyStr p.default}"'' else "";
          in
          ''_parser.add_argument("${varName}"${nargsStr}${def}, help="${escPyStr p.desc}")''
        ) params
      );
    in
    let
      epilogStr =
        if hasExamples s then
          let
            lines = map (e: "  ${escPyStr e.cmd}  ${escPyStr e.desc}") s.examples;
            epilog = "Examples:\\n" + (builtins.concatStringsSep "\\n" lines);
          in
          '', epilog="${epilog}", formatter_class=_argparse.RawDescriptionHelpFormatter''
        else
          "";
    in
    ''
      import argparse as _argparse
      _parser = _argparse.ArgumentParser(prog="${escPyStr (getDisplayName s)}", description="${escPyStr s.desc}"${epilogStr})
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
      dn = getDisplayName s;
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
          echo "${escFishDQ dn} - ${escFishDQ s.desc}"
          echo ""
          echo "Usage: ${escFishDQ usage}"
        ${paramHelp}
        ${lib.optionalString enhanced ''
          echo ""
          echo "  -v, --verbose    Show debug output"
          echo "  -h, --help       Show this help"
        ''}
        ${fishExamplesHelp s}
          exit 0
        end

        ${lib.optionalString (hasFlags s) (fishArgparse s flags)}

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
              lines = map (
                p: "        print(\"  %-14s %s\" % (\"${escPyStr p.name}\", \"${escPyStr p.desc}\"))"
              ) s.params;
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
                "        print(\"  %-14s %s\" % (\"${escPyStr label}\", \"${escPyStr f.desc}\"))"
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
              print("${escPyStr (getDisplayName s)} - ${escPyStr s.desc}")
              print()
              print("Usage: ${usage}")
          ${pythonParamHelp}
          ${pythonExamplesHelp s}
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

  # ── Subcommand group builder ────────────────────────────────────────
  mkSubcommandGroup =
    group:
    let
      parentName = group.name;
      subs = group.subs;

      # Build each subcommand as a standalone script with name "<parent>--<sub>"
      # Set displayName so help text shows "parent sub" instead of "parent--sub"
      subDerivations = map (
        sub: mkBin (sub // {
          name = "${parentName}--${sub.name}";
          displayName = "${parentName} ${sub.name}";
        })
      ) (builtins.filter isBin subs);

      # Build help lines for subcommands
      subHelpLines = builtins.concatStringsSep "\n" (
        map (sub: "  printf '  %-18s %s\\n' '${escSQ sub.name}' '${escSQ sub.desc}'") subs
      );

      # Parent dispatch script
      dispatchScript = pkgs.writeTextFile {
        name = parentName;
        executable = true;
        destination = "/bin/${parentName}";
        text = ''
          #!/usr/bin/env fish

          if test (count $argv) -eq 0; or contains -- --help $argv; or contains -- -h $argv
            echo "${escFishDQ parentName} - subcommands"
            echo ""
            echo "Usage: ${escFishDQ parentName} <command> [args...]"
            echo ""
            echo "Commands:"
          ${subHelpLines}
            exit 0
          end

          set -l subcmd $argv[1]
          set -e argv[1]

          set -l bin "${parentName}--$subcmd"
          if command -q $bin
            exec $bin $argv
          else
            echo "Unknown command: ${escFishDQ parentName} $subcmd" >&2
            echo "Run '${escFishDQ parentName} --help' for available commands." >&2
            exit 1
          end
        '';
      };
    in
    {
      derivations = subDerivations ++ [ dispatchScript ];
      inherit parentName subs;
    };

  builtGroups = map mkSubcommandGroup subcommandGroups;
  subcommandDerivations = builtins.concatLists (map (g: g.derivations) builtGroups);

  # ── Derivations ────────────────────────────────────────────────────
  binScripts = builtins.filter isBin scripts;
  functionScripts = builtins.filter isFunction scripts;
  scriptDerivations = map mkBin binScripts;

  # ── bins command ───────────────────────────────────────────────────
  flatBinsLines = builtins.concatStringsSep "\n" (
    map (s: "  printf '  %-18s %s\\n' '${escSQ s.name}' '${escSQ s.desc}'") scripts
  );
  groupBinsLines = builtins.concatStringsSep "\n" (
    builtins.concatLists (
      map (
        g:
        [ "  echo ''" "  printf '  %-18s %s\\n' '${escSQ g.parentName}' 'subcommands:'" ]
        ++ (map (
          sub: "  printf '    %-16s %s\\n' '${escSQ sub.name}' '${escSQ sub.desc}'"
        ) g.subs)
      ) builtGroups
    )
  );
  binsLines = flatBinsLines + "\n" + groupBinsLines;

  # ── fzf entries for interactive mode ─────────────────────────────
  fzfEntries =
    let
      flatEntries = map (s: "${s.name}\t${s.desc}") scripts;
      groupEntries = builtins.concatLists (
        map (
          g:
          map (sub: "${g.parentName} ${sub.name}\t${sub.desc}") g.subs
        ) builtGroups
      );
    in
    builtins.concatStringsSep "\\n" (flatEntries ++ groupEntries);

  binsScript = pkgs.writeTextFile {
    name = "bins";
    executable = true;
    destination = "/bin/bins";
    text = ''
      #!/usr/bin/env fish

      if contains -- --help $argv; or contains -- -h $argv
        echo "bins - List all custom scripts"
        echo ""
        echo "Usage: bins [-i/--interactive] [help <command>]"
        echo ""
        echo "  -i, --interactive  Fuzzy-find and execute a script"
        echo "  help <command>     Show help for a command"
        exit 0
      end

      if test (count $argv) -ge 2; and test "$argv[1]" = "help"
        set -l cmd $argv[2]
        if command -q $cmd
          exec $cmd --help
        else
          echo "Unknown command: $cmd" >&2
          exit 1
        end
      end

      if contains -- -i $argv; or contains -- --interactive $argv
        # Remove the -i/--interactive flag from argv
        set -l remaining
        for arg in $argv
          if test "$arg" != "-i"; and test "$arg" != "--interactive"
            set -a remaining $arg
          end
        end

        set -l choice (printf '${fzfEntries}\n' | ${pkgs.fzf}/bin/fzf --prompt='bins> ' --delimiter='\t' --with-nth=1.. --tabstop=20)
        or exit 0
        set -l cmd (string split -m1 \t $choice)[1]
        set -l parts (string split ' ' $cmd)
        $parts $remaining
        exit $status
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
              "complete -c ${s.name} -l ${longName}${shortPart}${requiresArg}${completionPart} -d \"${escFishDQ (f.desc or "a flag")}\""
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

  binsCompletionCmds = builtins.concatStringsSep "\n" (
    map (s: "complete -c bins -f -n '__fish_seen_subcommand_from help' -a '${s.name}' -d '${escFishDQ s.desc}'") scripts
  );
  binsCompletion = {
    "fish/completions/bins.fish".text = ''
      complete -c bins -f -l help -s h -d "Show help"
      complete -c bins -f -l interactive -s i -d "Fuzzy-find and execute a script"
      complete -c bins -f -n '__fish_use_subcommand' -a 'help' -d 'Show help for a command'
      ${binsCompletionCmds}
    '';
  };

  # ── Subcommand completions ──────────────────────────────────────────
  mkSubcommandCompletion =
    g:
    let
      parentName = g.parentName;
      # Complete subcommand names when no subcommand given yet
      subLines = builtins.concatStringsSep "\n" (
        map (
          sub:
          "complete -c ${parentName} -f -n '__fish_use_subcommand' -a '${sub.name}' -d '${escFishDQ sub.desc}'"
        ) g.subs
      );
      # Complete flags/params for each subcommand
      subFlagLines = builtins.concatStringsSep "\n" (
        builtins.concatLists (
          map (
            sub:
            let
              cond = "-n '__fish_seen_subcommand_from ${sub.name}'";
              flagLines =
                if hasFlags sub then
                  map (
                    f:
                    let
                      longName = normalizeFlagName f.name;
                      sh = flagShort f;
                      shortPart = if sh != "" then " -s ${sh}" else "";
                      requiresArg = if !(flagIsBool f) then " -r" else "";
                    in
                    "complete -c ${parentName} -f ${cond} -l ${longName}${shortPart}${requiresArg} -d '${escFishDQ (f.desc or "a flag")}'"
                  ) (sub.flags or [ ])
                else
                  [ ];
              paramLines =
                if hasParams sub then
                  builtins.filter (l: l != "") (
                    map (
                      p:
                      if p ? completions && p.completions != "" then
                        let
                          escaped = builtins.replaceStrings [ "'" ] [ "'\\''" ] p.completions;
                        in
                        "complete -c ${parentName} -f ${cond} -a '(${escaped})'"
                      else
                        ""
                    ) sub.params
                  )
                else
                  [ ];
            in
            flagLines ++ paramLines
          ) g.subs
        )
      );
    in
    {
      "fish/completions/${parentName}.fish".text =
        "complete -c ${parentName} -f -l help -s h -d 'Show help'\n"
        + subLines
        + (if subFlagLines != "" then "\n" + subFlagLines else "")
        + "\n";
    };

  subcommandCompletions = builtins.foldl' (acc: g: acc // mkSubcommandCompletion g) { } builtGroups;

  allCompletions =
    (builtins.foldl' (acc: s: acc // mkCompletion s) { } (builtins.filter isBin scripts))
    // subcommandCompletions
    // binsCompletion;

in
{
  home.packages = scriptDerivations ++ subcommandDerivations ++ [ binsScript ];

  programs.fish.functions = builtins.listToAttrs (
    map (s: {
      name = s.name;
      value = s.body;
    }) functionScripts
  );

  xdg.configFile = allCompletions;
}
