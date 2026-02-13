---
name: gh-pr-review
description: Use when viewing, replying to, or managing inline GitHub PR review comments and threads from the terminal
---

# gh-pr-review

GitHub CLI extension for inline PR review comments with LLM-friendly JSON output.

## Shell Wrapper

`ghreview` auto-detects repo and PR from the current directory/branch. All args pass through to `gh pr-review`.

```sh
# These are equivalent:
ghreview review view --unresolved
gh pr-review review view --unresolved -R owner/repo 42

# Exclude bot comments (filters author_login ending in [bot])
ghreview --no-bots review view
```

Override auto-detection with `-R owner/repo` and/or a trailing PR number.

## Core Commands

### View Reviews and Threads

```sh
ghreview review view
ghreview review view --unresolved --not_outdated
ghreview review view --reviewer octocat
ghreview review view --states CHANGES_REQUESTED,COMMENTED
ghreview review view --tail 1
ghreview --no-bots review view --unresolved
```

| Flag | Purpose |
|------|---------|
| `--reviewer <login>` | Filter by reviewer |
| `--states <list>` | APPROVED, CHANGES_REQUESTED, COMMENTED, DISMISSED |
| `--unresolved` | Only unresolved threads |
| `--not_outdated` | Exclude outdated threads |
| `--tail <n>` | Keep last n replies per thread |
| `--include-comment-node-id` | Add GraphQL comment IDs |

### Reply to Threads

```sh
ghreview comments reply --thread-id PRRT_xxx --body "Addressed in latest commit"
```

### List Threads

```sh
ghreview threads list --unresolved --mine
```

### Resolve / Unresolve Threads

```sh
ghreview threads resolve --thread-id PRRT_xxx
ghreview threads unresolve --thread-id PRRT_xxx
```

### Create and Submit Reviews

```sh
# Start pending review
ghreview review --start

# Add inline comment
ghreview review --add-comment \
  --review-id PRR_xxx \
  --path src/file.go \
  --line 42 \
  --body "nit: use helper"

# Submit
ghreview review --submit \
  --review-id PRR_xxx \
  --event REQUEST_CHANGES \
  --body "Please address the comments"
```

Events: `APPROVE`, `REQUEST_CHANGES`, `COMMENT`

## Output Format

Structured JSON. IDs use GraphQL format: `PRR_` (reviews), `PRRT_` (threads), `PRRC_` (comments).

```json
{
  "reviews": [
    {
      "id": "PRR_...",
      "state": "CHANGES_REQUESTED",
      "author_login": "reviewer",
      "comments": [
        {
          "thread_id": "PRRT_...",
          "path": "src/file.go",
          "author_login": "reviewer",
          "body": "Consider refactoring this",
          "is_resolved": false,
          "is_outdated": false,
          "thread_comments": [
            {
              "author_login": "author",
              "body": "Good point, will fix"
            }
          ]
        }
      ]
    }
  ]
}
```

## Common Workflows

### Get actionable review feedback

```sh
ghreview --no-bots review view --unresolved --not_outdated
```

### Reply and resolve

```sh
# Get thread IDs
ghreview threads list --unresolved

# Reply
ghreview comments reply --thread-id PRRT_xxx --body "Fixed in abc123"

# Resolve
ghreview threads resolve --thread-id PRRT_xxx
```

### Full review cycle

```sh
ghreview review --start
ghreview review --add-comment --review-id PRR_xxx --path file.go --line 10 --body "Issue here"
ghreview review --submit --review-id PRR_xxx --event REQUEST_CHANGES --body "See inline comments"
```
