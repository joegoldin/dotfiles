---
name: git-hunk
description: Use when you need to stage, unstage, or inspect individual git hunks non-interactively — especially for crafting precise commits from mixed changes
---

# git-hunk: Non-Interactive Hunk Staging

`git-hunk` enables deterministic staging of git hunks using content hashes instead of interactive prompts. This is essential for Claude Code since `git add -p` requires interactive input.

## Core Workflow

1. **List** hunks to see what's changed and get their hashes
2. **Add/Reset** specific hunks by hash to stage exactly what you want
3. **Commit** the staged changes

## Commands

### List hunks

```bash
git hunk list                    # All unstaged hunks with full diffs
git hunk list --oneline          # Compact — just hashes and summaries
git hunk list --staged           # Show staged hunks
git hunk list --file path/to/file # Filter to one file
git hunk list --porcelain        # Machine-readable tab-separated output
```

### Stage hunks

```bash
git hunk add <hash>              # Stage one hunk (4+ char prefix match)
git hunk add <hash1> <hash2>     # Stage multiple hunks
git hunk add --all               # Stage everything
git hunk add --file path/to/file # Stage all hunks in a file
git hunk add <hash>:3-5,8        # Stage specific lines within a hunk
```

### Unstage hunks

```bash
git hunk reset <hash>            # Unstage one hunk
git hunk reset --all             # Unstage everything
git hunk reset --file path/to/file
```

### Inspect

```bash
git hunk diff <hash>             # Full diff of a specific hunk
git hunk diff <hash>:3-5         # Preview specific lines
git hunk count                   # Count unstaged hunks
git hunk count --staged          # Count staged hunks
git hunk check <hash>            # Verify a hash is still valid
```

### Restore (discard changes)

```bash
git hunk restore <hash>          # Discard a hunk from worktree
git hunk restore --dry-run <hash> # Preview before discarding
```

### Stash

```bash
git hunk stash <hash>            # Stash specific hunks
git hunk stash --all             # Stash all tracked changes
git hunk stash -m "message"      # With message
git hunk stash pop               # Restore most recent stash
```

## When to Use

- **Crafting precise commits**: When a file has multiple unrelated changes and you need to split them into separate commits
- **Staging partial work**: When only some changes in a file are ready to commit
- **Reviewing changes granularly**: Use `git hunk list` to see changes broken into logical hunks with stable hashes

## How Hashing Works

Each hunk gets a 7-character SHA-1 hash derived from file path, line number, and diff content (excluding context). Hashes remain stable as other hunks are staged, so multi-step staging is predictable.

## Useful Flags

- `--oneline`: Compact output without diffs
- `--porcelain`: Machine-readable for scripting
- `-U1`: Fine-grained hunks with 1 line of context (changes hashing)
- `--tracked-only`: Exclude untracked files
- `--quiet/-q`: Suppress output except errors
- `--verbose/-v`: Include summary counts
