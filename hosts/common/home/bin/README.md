# bin - Script Builder

Generates CLI tools from Nix attrset definitions in `scripts/`. Each `.nix` file defines one command with metadata, and the builder produces an executable with auto-generated help, flag parsing, completions, and color output.

Run `bins` to list all available commands, or `bins -i` to fuzzy-find and execute one.

## Script Types

The script body is written as a field named after the language. The builder derives the type automatically.

| Field | Shell | Flag Parsing | Notes |
|---|---|---|---|
| `fish` | fish | `argparse` builtin | Default. `$_flag_*` variables |
| `bash` | bash | `getopt` | Strict mode, cleanup traps |
| `python` | python3 | `argparse` module | `pythonPackages` for deps |
| `python-argparse` | python3 | manual | Raw python, no auto-generation |
| `function` | fish | N/A | Fish function (no wrapper script) |

Using the language name as the field enables tree-sitter injection for syntax highlighting in editors that support it.

## Minimal Example

```nix
# scripts/greet.nix
{
  name = "greet";
  desc = "Say hello";
  fish = ''
    echo "Hello, $argv[1]!"
  '';
}
```

## Subcommand Groups

Place `.nix` files in a subdirectory of `scripts/` to create a command group with subcommands. The directory name becomes the parent command, and each file becomes a subcommand.

```
scripts/
  ai/
    ask.nix      -> `ai ask`
    raw.nix      -> `ai raw`
    image.nix    -> `ai image`
```

```nix
# scripts/ai/ask.nix
{
  name = "ask";
  desc = "Query Claude with a question";
  fish = ''
    claude --bare -p (string join ' ' $argv)
  '';
}
```

```nix
# scripts/ai/image.nix
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

Each subcommand `.nix` file uses the same format as a top-level script — all features (flags, params, runtimeInputs, etc.) work the same way.

## Full Feature Example

```nix
# scripts/deploy.nix
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
  bash = ''
    echo "Deploying $1 from branch $branch"
  '';
}
```

## Flag Definition

Always declare flags in the `flags` field rather than parsing them manually with `argparse`, `contains`, or switch/case. The builder auto-generates `argparse` calls, `--help` text, fish completions, env var overrides, and required validation from the declaration. Manual parsing bypasses all of this.

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

When flags or `runtimeInputs`/`beforeExit` are present, scripts get:

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

Scripts without these features produce the same output as before (backward compatible).

## Accessing Parsed Values

| Type | Flags | Positional Args |
|---|---|---|
| fish | `$_flag_<name>` | `$argv[1]`, `$argv[2]`, ... |
| bash | `$<name>` (underscored) | `$1`, `$2`, ... (after getopt) |
| python | `_args.<name>` | `_args.<param_name>` |

Flag names are normalized: `--dry-run` becomes `$_flag_dry_run` (fish), `$dry_run` (bash), `_args.dry_run` (python).

## Python Packages

Python scripts can declare pip dependencies:

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

## Scripts Needing pkgs

If a script needs access to `pkgs` (for `runtimeInputs`), export a function:

```nix
# scripts/deploy.nix
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

## Interactive Mode

`bins -i` launches a fuzzy finder (fzf) over all scripts and subcommands. Select one to execute it. Extra arguments are passed through:

```sh
bins -i                    # fuzzy-find and run a script
bins -i --raw "question"   # select a script, run it with those args
```
