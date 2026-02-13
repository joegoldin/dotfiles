---
name: obsidian-cli
description: Use when interacting with Obsidian vaults and their markdown notes from the command line - reading, writing, searching notes, managing tasks, properties, tags, or any vault automation via the obsidian CLI
---

# Obsidian CLI

## Overview

Command-line interface for controlling Obsidian from the terminal. Requires Obsidian 1.12+ running.

**Core syntax:** `obsidian <command> [param=value...] [flags]`

## Vault: "Main Vault"

Located at `~/Obsidian/Main Vault`. When cwd is this path, no `vault=` prefix needed.

### Folder Structure

| Folder | Purpose |
|--------|---------|
| `Notes/` | Main content — standalone notes, work docs. Default location for new files. |
| `Notes/Journal/` | Daily notes. Files named `YYYY-MM-DD.md`. |
| `Notes/Recordings/` | Scribe audio transcriptions. |
| `Templates/` | Templater templates and Copilot custom prompts. |
| `Web Clippings/` | Saved web articles. Named `YYYY-MM-DD Web Clipping - Title.md`. |
| `Misc/` | Miscellaneous topic folders. |
| `attachments/` | Media/attachment storage. |
| `Excalidraw/` | Excalidraw drawings. |

### Frontmatter Conventions

**Daily notes:**
```yaml
created: 2026-02-11 08:45
tags:
  - type/daily
```

**Web clippings:**
```yaml
title: Article Title
source: https://...
author:
published: 2024-02-21
created: 2025-03-12
description: ...
tags:
  - type/clipping
ai-summary: ...
```

**General notes** typically have `created` and `tags` at minimum.

### Daily Note Structure

Template: `Templates/Daily Notes Template` (auto-applied via Templater to `Notes/Journal/`).

Sections:
1. `## Notes created today` — dataview query listing notes created that day
2. `## Today's thoughts` — freeform H3 subsections for meetings, ideas, tasks

A second template (`Daily Notes Template With Tasks`) adds task sections (Overdue, Today, Upcoming) using the Tasks plugin query syntax.

### Task Conventions

Uses **obsidian-tasks-plugin** with emoji format and custom statuses:

| Status char | Meaning |
|-------------|---------|
| ` ` (space) | Todo |
| `x` | Done |
| `/` | In Progress |
| `-` | Cancelled |
| `>` | Rescheduled |
| `<` | Scheduled |
| `!` | Important |
| `?` | Question |
| `*` | Star |
| `n` | Note |
| `i` | Information |
| `I` | Idea |
| `p` | Pro |
| `c` | Con |
| `b` | Bookmark |

Tasks often appear in daily notes with inline dates and nested tags.

### Key Plugins

| Plugin | Purpose |
|--------|---------|
| obsidian-tasks-plugin | Task management with custom statuses |
| dataview | Complex data queries in notes |
| templater-obsidian | Advanced templates (auto-applies to Journal folder) |
| omnisearch | Enhanced search (Cmd+O) |
| scribe | Audio transcription via OpenAI (stores in Notes/Recordings) |
| obsidian-excalidraw-plugin | Diagramming |
| calendar | Calendar navigation |
| nldates-obsidian | Natural language dates (Alt+T) |
| obsidian-linter | Markdown formatting on save |
| homepage | Opens to Daily Note on startup |
| tray | System tray with quick note (Cmd+Shift+Q) |

### Tag Taxonomy

Tags use nested `/` hierarchy. Clicking a parent tag in the tag pane shows all children. Run `obsidian tags all` for the current full list. The top-level categories and structure:

| Category | Location | Purpose | Examples |
|----------|----------|---------|----------|
| `type/*` | frontmatter | What kind of note | `type/daily`, `type/clipping`, `type/blog`, `type/task` |
| `work/*` | inline | Employer/work topics (nests further) | `#work/<employer>`, `#work/<employer>/<project>` |
| `project/*` | inline | Personal/side projects | `#project/<name>` |
| `tech/*` | inline | Technologies | `#tech/nix`, `#tech/elixir`, `#tech/swiftui` |
| `personal/*` | inline | Personal topics | `#personal/<topic>` |

## Key Concepts

- **Vault targeting:** Commands must be run from the vault root (the folder containing `.obsidian/`). For "Main Vault", that's `~/Obsidian/Main Vault`. Alternatively, prefix `vault=<name>` to target a vault from any directory.
- **File targeting:** `file=<name>` resolves like wikilinks (by name, no path/ext needed). `path=<path>` requires exact path from vault root.
- **Default target:** Most commands default to the active file if no file/path given.
- **Content:** Use `\n` for newline, `\t` for tab. Quote values with spaces.
- **Output:** Add `--copy` to any command to copy output to clipboard.
- **Flags** are boolean switches (no value). **Parameters** take `key=value`.

## Quick Reference

### Files & Content

| Command | Purpose | Key Params |
|---------|---------|------------|
| `read` | Read file contents | `file=` `path=` |
| `create` | Create/overwrite file | `name=` `content=` `template=` `overwrite` `silent` |
| `append` | Append to file | `content=` (req) `file=` `inline` |
| `prepend` | Prepend after frontmatter | `content=` (req) `file=` `inline` |
| `open` | Open a file | `file=` `path=` `newtab` |
| `move` | Move/rename file | `to=` (req) `file=` |
| `delete` | Delete file (trash) | `file=` `permanent` |
| `file` | Show file info | `file=` `path=` |
| `files` | List vault files | `folder=` `ext=` `total` |
| `folder` | Show folder info | `path=` (req) `info=files\|folders\|size` |
| `folders` | List vault folders | `folder=` `total` |

### Daily Notes

| Command | Purpose | Key Params |
|---------|---------|------------|
| `daily` | Open daily note | `silent` `paneType=tab\|split\|window` |
| `daily:read` | Read daily note contents | |
| `daily:append` | Append to daily note | `content=` (req) `silent` `inline` |
| `daily:prepend` | Prepend to daily note | `content=` (req) `silent` `inline` |

### Search

| Command | Purpose | Key Params |
|---------|---------|------------|
| `search` | Search vault text | `query=` (req) `path=` `limit=` `format=text\|json` `total` `matches` `case` |

### Tasks

| Command | Purpose | Key Params |
|---------|---------|------------|
| `tasks` | List tasks | `file=` `all` `daily` `todo` `done` `total` `verbose` `status="<char>"` |
| `task` | Show/update a task | `ref=<path:line>` `file=` `line=` `toggle` `done` `todo` `daily` `status="<char>"` |

### Tags

| Command | Purpose | Key Params |
|---------|---------|------------|
| `tags` | List tags | `file=` `all` `counts` `total` `sort=count` |
| `tag` | Get tag info | `name=` (req) `total` `verbose` |

### Properties (Frontmatter)

| Command | Purpose | Key Params |
|---------|---------|------------|
| `properties` | List properties | `file=` `all` `name=` `counts` `total` `format=yaml\|tsv` `sort=count` |
| `property:set` | Set property on file | `name=` `value=` (req) `type=text\|list\|number\|checkbox\|date\|datetime` `file=` |
| `property:remove` | Remove property | `name=` (req) `file=` |
| `property:read` | Read property value | `name=` (req) `file=` |
| `aliases` | List aliases | `file=` `all` `total` `verbose` |

### Links & Structure

| Command | Purpose | Key Params |
|---------|---------|------------|
| `backlinks` | Backlinks to file | `file=` `counts` `total` |
| `links` | Outgoing links | `file=` `total` |
| `unresolved` | Unresolved links in vault | `total` `counts` `verbose` |
| `orphans` | No incoming links | `total` `all` |
| `deadends` | No outgoing links | `total` `all` |
| `outline` | Show headings | `file=` `format=tree\|md` `total` |
| `wordcount` | Word/char count | `file=` `words` `characters` |

### Bookmarks

| Command | Purpose | Key Params |
|---------|---------|------------|
| `bookmarks` | List bookmarks | `total` `verbose` |
| `bookmark` | Add bookmark | `file=` `folder=` `search=` `url=` `title=` `subpath=` |

### Templates

| Command | Purpose | Key Params |
|---------|---------|------------|
| `templates` | List templates | `total` |
| `template:read` | Read template content | `name=` (req) `resolve` `title=` |
| `template:insert` | Insert into active file | `name=` (req) |

### Commands & Hotkeys

| Command | Purpose | Key Params |
|---------|---------|------------|
| `commands` | List command IDs | `filter=` |
| `command` | Execute any Obsidian command | `id=` (req) |
| `hotkeys` | List hotkeys | `total` `all` `verbose` |
| `hotkey` | Get hotkey for command | `id=` (req) `verbose` |

### Vault & Workspace

| Command | Purpose | Key Params |
|---------|---------|------------|
| `vault` | Show vault info | `info=name\|path\|files\|folders\|size` |
| `vaults` | List known vaults | `total` `verbose` |
| `workspace` | Show workspace tree | `ids` |
| `workspaces` | List saved workspaces | `total` |
| `workspace:save` | Save workspace | `name=` |
| `workspace:load` | Load workspace | `name=` (req) |
| `workspace:delete` | Delete workspace | `name=` (req) |
| `tabs` | List open tabs | `ids` |
| `tab:open` | Open new tab | `group=` `file=` `view=` |
| `recents` | Recently opened files | `total` |
| `random` | Open random note | `folder=` `newtab` `silent` |
| `random:read` | Read random note | `folder=` |

### Plugins

| Command | Purpose | Key Params |
|---------|---------|------------|
| `plugins` | List plugins | `filter=core\|community` `versions` |
| `plugins:enabled` | List enabled plugins | `filter=` `versions` |
| `plugins:restrict` | Toggle restricted mode | `on` `off` |
| `plugin` | Plugin info | `id=` (req) |
| `plugin:enable` | Enable plugin | `id=` (req) `filter=` |
| `plugin:disable` | Disable plugin | `id=` (req) `filter=` |
| `plugin:install` | Install community plugin | `id=` (req) `enable` |
| `plugin:uninstall` | Uninstall plugin | `id=` (req) |
| `plugin:reload` | Reload plugin (dev) | `id=` (req) |

### Developer

| Command | Purpose | Key Params |
|---------|---------|------------|
| `eval` | Execute JavaScript | `code=` (req) |
| `dev:screenshot` | Take screenshot (base64 PNG) | `path=` |
| `dev:console` | Show console messages | `limit=` `level=log\|warn\|error\|info\|debug` `clear` |
| `dev:errors` | Show JS errors | `clear` |
| `dev:css` | Inspect CSS | `selector=` (req) `prop=` |
| `dev:dom` | Query DOM elements | `selector=` (req) `attr=` `css=` `text` `inner` `all` `total` |
| `dev:mobile` | Toggle mobile emulation | `on` `off` |
| `dev:debug` | Attach/detach CDP debugger | `on` `off` |
| `dev:cdp` | Run CDP command | `method=` (req) `params=` |
| `devtools` | Toggle dev tools | |

### File History

| Command | Purpose | Key Params |
|---------|---------|------------|
| `diff` | List/compare versions | `file=` `from=` `to=` `filter=local\|sync` |
| `history` | List local versions | `file=` |
| `history:list` | List all files with history | |
| `history:read` | Read local version | `file=` `version=` |
| `history:restore` | Restore local version | `file=` `version=` (req) |
| `history:open` | Open file recovery | `file=` |

### Sync

| Command | Purpose | Key Params |
|---------|---------|------------|
| `sync` | Pause/resume sync | `on` `off` |
| `sync:status` | Show sync status | |
| `sync:history` | Sync version history | `file=` `total` |
| `sync:read` | Read sync version | `file=` `version=` (req) |
| `sync:restore` | Restore sync version | `file=` `version=` (req) |
| `sync:open` | Open sync history | `file=` |
| `sync:deleted` | List deleted files | `total` |

### Publish

| Command | Purpose | Key Params |
|---------|---------|------------|
| `publish:site` | Show publish site info | |
| `publish:list` | List published files | `total` |
| `publish:status` | List publish changes | `total` `new` `changed` `deleted` |
| `publish:add` | Publish file | `file=` `changed` |
| `publish:remove` | Unpublish file | `file=` |
| `publish:open` | Open on published site | `file=` |

### Themes & Snippets

| Command | Purpose | Key Params |
|---------|---------|------------|
| `themes` | List themes | `versions` |
| `theme` | Active theme / theme info | `name=` |
| `theme:set` | Set theme | `name=` (req) |
| `theme:install` | Install theme | `name=` (req) `enable` |
| `theme:uninstall` | Uninstall theme | `name=` (req) |
| `snippets` | List CSS snippets | |
| `snippets:enabled` | List enabled snippets | |
| `snippet:enable` | Enable snippet | `name=` (req) |
| `snippet:disable` | Disable snippet | `name=` (req) |

### Bases

| Command | Purpose | Key Params |
|---------|---------|------------|
| `bases` | List .base files | |
| `base:views` | List views in current base | |
| `base:query` | Query a base | `file=` `view=` `format=json\|csv\|tsv\|md\|paths` |
| `base:create` | Create base item | `name=` `content=` `silent` `newtab` |

### Unique Notes

| Command | Purpose | Key Params |
|---------|---------|------------|
| `unique` | Create unique note | `name=` `content=` `paneType=` `silent` |

### Web Viewer

| Command | Purpose | Key Params |
|---------|---------|------------|
| `web` | Open URL in web viewer | `url=` (req) `newtab` |

### General

| Command | Purpose |
|---------|---------|
| `help` | Show all commands |
| `version` | Show Obsidian version |
| `reload` | Reload app window |
| `restart` | Restart app |

## Common Patterns

```bash
# Daily note workflow
obsidian daily                         # Open today's daily note
obsidian daily:read                    # Read today's note contents
obsidian daily:append content="- [ ] Review PR" silent
obsidian daily:append content="\n### Standup #work/acme\n- updates here" silent

# Task management
obsidian tasks daily todo              # Incomplete daily tasks
obsidian tasks daily done              # Completed daily tasks
obsidian task daily line=15 done       # Mark specific daily task done
obsidian task daily line=8 status=/    # Mark as in-progress
obsidian tasks all todo verbose        # All open tasks across vault with file paths

# Reading and searching
obsidian read file="2026-02-11"        # Read a journal entry by date
obsidian read path="Web Clippings/2025-03-12 Web Clipping - Obsidian Physical Object System and Template.md"
obsidian search query="work/acme" matches     # Search for work-related notes
obsidian search query="1:1" path="Notes/Journal" matches

# Creating notes
obsidian create name="Meeting Notes" content="# Meeting\n\n- " silent
obsidian create name="2026-02-12" path="Notes/Journal/2026-02-12.md" template="Daily Notes Template" silent

# Properties
obsidian property:set name=tags value=work/acme file=MyNote
obsidian property:read name=created file="2026-02-11"

# Vault exploration
obsidian tags all counts sort=count    # See all tags by frequency
obsidian files folder="Notes/Journal" total  # Count journal entries
obsidian files folder="Web Clippings"  # List web clippings

# Run JS in Obsidian context
obsidian eval code="app.vault.getFiles().length"
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Obsidian not running | CLI requires running Obsidian instance |
| Using `path=` for simple lookups | `file=` resolves like wikilinks — simpler for unique names |
| Unquoted spaced values | `content="Hello world"` not `content=Hello world` |
| Forgetting `silent` flag | Without it, create/open commands will focus Obsidian window |
| Wrong vault targeted | Check cwd or use explicit `vault=` prefix |
