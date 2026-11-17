# bin - Script Builder

Generates CLI tools from Nix attrset definitions in `_scripts/`. Each `.nix` file defines one command with metadata, and the builder produces an executable with auto-generated help, flag parsing, completions, and color output.

Run `bins` to list all available commands, or `bins -i` to fuzzy-find and execute one.

## Script Types

The script body is written as a field named after the language. The builder derives the type automatically.

| Field | Shell | Flag Parsing | Notes |
|---|---|---|---|
| `fish` | fish | `argparse` builtin | `$_flag_*` variables |
| `bash` | bash | `getopt` | Strict mode, cleanup traps |
| `python` | python3 | `argparse` module | `pythonPackages` for deps |
| `python-argparse` | python3 | manual | Raw python, no auto-generation |
| `function` | fish | N/A | Fish function (no wrapper script) |

Using the language name as the field enables tree-sitter injection for syntax
highlighting in editors that support it. Select a language explicitly; older
`type` + `body` definitions are also accepted.

The den aspect in [`default.nix`](default.nix) imports the standalone Home
Manager module [`_module.nix`](_module.nix). MicroVM guests import that module
directly and set `vmGuest = true` to exclude top-level scripts marked
`hostOnly = true`. The `vm` subcommand group is Linux-only.

## Minimal Example

```nix
# _scripts/greet.nix
{
  name = "greet";
  desc = "Say hello";
  fish = ''
    echo "Hello, $argv[1]!"
  '';
}
```

## Subcommand Groups

Place `.nix` files in a subdirectory of `_scripts/` to create a command group
with subcommands. The directory name becomes the parent command, and each
file becomes a subcommand. The following `ai` group is an example, not an
installed group; the repository currently defines `vm`.

```
_scripts/
  ai/
    ask.nix      -> `ai ask`
    raw.nix      -> `ai raw`
    image.nix    -> `ai image`
```

```nix
# _scripts/ai/ask.nix
{
  name = "ask";
  desc = "Query Claude with a question";
  fish = ''
    claude --bare -p (string join ' ' $argv)
  '';
}
```

```nix
# _scripts/ai/image.nix
{
  name = "image";
  desc = "Analyze an image with Claude";
  fish = ''
    set -l latest (command ls -t ~/Downloads/*.{png,jpg,jpeg} 2>/dev/null | head -1)
    claude --bare -p "Read the image at $latest. "(string join ' ' $argv)
  '';
}
```

The builder auto-generates:
- A parent dispatcher script (`ai`) that routes to subcommands
- `ai --help` listing all subcommands with descriptions
- Fish completions for subcommand names and their flags

Each subcommand `.nix` file uses the same format as a top-level script; all features (flags, params, runtimeInputs, etc.) work the same way.

## Full Feature Example

```nix
# _scripts/deploy.nix
{ pkgs }:
{
  name = "deploy";
  desc = "Deploy the application";
  strict = true;              # set -euo pipefail (default: true)
  autoparse = true;           # auto getopt parsing (default: true)
  runtimeInputs = [ pkgs.curl pkgs.jq ]; # added to PATH
  beforeExit = ''
    rm -f "$tmpfile"
  '';
  params = [
    {
      name = "TARGET";
      desc = "Deployment target";
      required = true;         # default: true for params
      completions = "echo 'staging\nproduction'"; # fish completion command
    }
  ];
  flags = [
    {
      name = "--dry-run";
      short = "-d";            # default: first char of flag name
      desc = "Show what would happen";
      bool = true;             # toggle flag, no value (default: false)
    }
    {
      name = "--branch";
      arg = "BRANCH";          # placeholder in help text
      desc = "Git branch to deploy";
      default = "main";        # default value
      envVar = "DEPLOY_BRANCH"; # env var override (default: POG_<UPPER_NAME>)
      required = false;        # die if not provided (default: false)
    }
  ];
  examples = [
    { cmd = "deploy staging"; desc = "Deploy to staging"; }
    { cmd = "deploy -d production"; desc = "Dry-run production deploy"; }
  ];
  bash = ''
    echo "Deploying $1 from branch $branch"
  '';
}
```

## Flag Definition

For generated parsing, declare flags in the `flags` field rather than parsing
them again in the body. The builder generates parsing, help, completions,
environment defaults, and required-flag validation from those declarations.
Short flags reserve `-h` and `-v`; collisions automatically try the opposite
case and fail evaluation if both letters are taken.

`python-argparse` is the explicit escape hatch for a script that owns its
whole CLI, as several `vm` commands do. It receives only the Python shebang
and body, not generated helpers, parsing, cleanup, or a `runtimeInputs` PATH
preamble. `pythonPackages` still selects its interpreter environment.
Bash's `autoparse = false` similarly disables generated parsing and required
validation; the body must handle them.

All fields except `name` and `desc` are optional:

```nix
{
  name = "--flag-name";     # long flag (with --)
  desc = "Help text";       # shown in --help output
  short = "-f";             # short flag (default: first char)
  bool = false;             # true = toggle, false = takes value
  default = "";             # default value
  arg = "VAR";              # value placeholder in help
  envVar = "MY_FLAG";       # env override (default: POG_FLAG_NAME)
  required = false;         # exit if missing
  completion = "cmd";       # fish completion command for flag values
}
```

## Auto-Generated Features

Generated Bash scripts include the help/parser/helper preamble by default.
Fish adds helpers when flags, `runtimeInputs`, or `beforeExit` are present;
Python also enables its generated argparse path when `params` are declared.
Depending on the selected language, these provide:

- **`--help` / `-h`** - auto-generated usage with all flags/params
- **`--verbose` / `-v`** - debug output toggle (auto-added)
- **`die()`** - print error to stderr and exit
- **`debug()`** - print only when `--verbose` is set
- **Color helpers** - `green()`, `red()`, `yellow()`, `blue()`, `bold()`
- **Env var overrides** - every flag checks `$POG_<NAME>` before using its default
- **Required validation** - flags with `required = true` exit if missing
- **Cleanup** - `beforeExit` code runs on script exit (trap/atexit/fish_exit)
- **PATH setup** - `runtimeInputs` packages prepended to PATH
- **Fish completions** - auto-generated for all flags and params
- **Examples** - shown in `--help` output when `examples` field is defined

Fish and Python's minimal paths still provide basic help, but do not gain all
these helpers. `function` entries are installed as fish functions without an
executable wrapper. Raw `python-argparse` bodies own their own help and error
handling. Declare flags and positional parameters, then inspect the generated
help rather than assuming every language has the same preamble.

## Accessing Parsed Values

| Type | Flags | Positional Args |
|---|---|---|
| fish | `$_flag_<name>` | `$argv[1]`, `$argv[2]`, ... |
| bash | `$<name>` (underscored) | `$1`, `$2`, ... (after getopt) |
| python | `_args.<name>` | `_args.<param_name>` |

Flag names are normalized: `--dry-run` becomes `$_flag_dry_run` (fish), `$dry_run` (bash), `_args.dry_run` (python).

## Python Packages

Python scripts can select packages from `pkgs.python3Packages`; this does not
run pip or install dependencies at runtime:

```nix
{
  name = "wallpaper";
  desc = "Set desktop wallpaper";
  pythonPackages = [ "pillow" "dbus-python" ];
  python = ''
    from PIL import Image
    # ...
  '';
}
```

## Package arguments

A script definition can be an attrset or a function. The module supplies the
function's declared `pkgs` and `customPackages` arguments; no other required
arguments are injected. Use `pkgs` for nixpkgs tools and `customPackages` for
composed local packages or upstream artifacts:

```nix
# _scripts/deploy.nix
{ pkgs }:
{
  name = "deploy";
  desc = "Deploy the application";
  runtimeInputs = [ pkgs.curl pkgs.jq ];
  bash = ''
    echo "deploying..."
  '';
}
```

For example, a definition using a composed application can accept
`{ pkgs, customPackages }` and include `customPackages.audiomemo` in
`runtimeInputs`. Standalone importers must supply `customPackages` too.
MicroVM guests deliberately pass an empty set; a reusable script should
handle an optional application explicitly, as
[`watchyt.nix`](_scripts/watchyt.nix) does, or be marked `hostOnly`.

## Interactive Mode and Help

```fish
bins                       # list all scripts
bins -i                    # fuzzy-find and run a script
bins -i --raw "question"   # select a script, run it with those args
bins help vm               # list the installed VM subcommands
vm new --help              # parent help also lists subcommands
vm--new --help             # the generated executable's detailed help
```
