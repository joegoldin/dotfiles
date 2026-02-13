---
name: claude-nix-config
description: Use when creating, editing, or managing Claude Code skills, commands, agents, or plugin configuration in this dotfiles repo
---

# Claude Nix Configuration

This dotfiles repo manages Claude Code declaratively via [claude-nix](https://github.com/joegoldin/claude-nix). All skills, commands, agents, and plugin settings are defined in Nix and built into a wrapped `claude` binary with plugins baked in.

## Key Files

| File | Purpose |
|------|---------|
| `hosts/common/home/claude/default.nix` | Main config — plugins, skills, commands, packages |
| `hosts/common/home/claude/settings.nix` | `settings.json` — permissions, hooks |
| `hosts/common/home/claude/skills/<name>/SKILL.md` | Local skill definitions |

## Architecture

```
claudeLib = import claude-nix/lib { pkgs = ...; }

claudeLib.mkPlugin    → creates a plugin (bundles skills + commands + agents)
claudeLib.mkSkill     → creates a skill derivation
claudeLib.mkCommand   → creates a slash command derivation
claudeLib.mkAgent     → creates an agent derivation
claudeLib.mkClaude    → wraps claude binary with --plugin-dir flags
```

The plugin is built and passed to `mkClaude`, which produces a wrapped `claude` binary installed via `home.packages`.

## Adding a Local Skill

1. Create `hosts/common/home/claude/skills/<skill-name>/SKILL.md` with frontmatter:

```markdown
---
name: my-skill
description: When to use this skill
---

# Skill content here
```

2. Register it in `default.nix`:

```nix
superpowersSkillDerivations = (map wrapSkill skillNames) ++ [
  (localSkill "executing-plans")
  (localSkill "gh-pr-review")
  (localSkill "obsidian-cli")
  (localSkill "my-skill")        # <-- add here
];
```

3. Rebuild: `darwin-rebuild switch --flake .`

## Adding a Nix-Inline Skill

For skills that reference nix packages or binaries:

```nix
mySkill = claudeLib.mkSkill {
  name = "my-tool";
  description = "When to use this";
  allowed-tools = ["Bash(${pkgs.sometool}/bin/sometool)"];
} ''
  Skill content referencing ${pkgs.sometool}/bin/sometool
'';
```

Then add `mySkill` to the plugin's `skills` list.

## Adding a Command (Slash Command)

Commands become `/command-name` in Claude Code.

```nix
myCommand = claudeLib.mkCommand {
  name = "my-command";
  description = "What this command does";
  allowed-tools = ["Bash" "Read" "Skill"];  # optional
  # argument-hint = "optional hint";        # optional
  # model = "claude-sonnet-4-20250514";     # optional model override
} ''
  Command prompt content here.
  Use $ARGUMENTS for user input.
'';
```

Then add to the plugin:

```nix
superpowersPlugin = claudeLib.mkPlugin {
  name = "superpowers";
  description = "...";
  skills = superpowersSkillDerivations;
  commands = [
    myCommand
  ];
};
```

## Adding an Agent

```nix
myAgent = claudeLib.mkAgent {
  name = "my-agent";
  description = "What this agent does";
  tools = ["Bash" "Read" "Write"];  # optional tool restrictions
  # model = "claude-haiku-4-20250514";  # optional model override
} ''
  Agent system prompt here.
'';
```

Then add to the plugin's `agents` list.

## Upstream Skills (superpowers)

Upstream skills come from `inputs.superpowers` (github:obra/superpowers). They are listed in `skillNames` and wrapped with `wrapSkill`. To add a new upstream skill, just add its name to the `skillNames` list.

To update upstream skills: `nix flake update superpowers`

## Settings (Permissions & Hooks)

Edit `settings.nix` to modify:
- `permissions.allow` / `permissions.deny` — tool access control
- `hooks` — shell commands triggered on events (Notification, Stop, PreToolUse)
- `defaultMode` — default permission mode

## Build & Apply

```sh
# In the dotfiles repo
darwin-rebuild switch --flake .

# Or for NixOS
sudo nixos-rebuild switch --flake .
```

Skills hot-reload in modern Claude Code, but commands and plugin structure require a rebuild.
