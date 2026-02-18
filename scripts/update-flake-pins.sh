#!/usr/bin/env bash
set -euo pipefail

# Update pinned flake inputs to latest versions
# - Tagged inputs (?ref=vX.Y.Z) -> latest tag
# - Commit inputs (?rev=abc123) -> latest commit on default branch
# - Unpinned inputs -> nix flake update

FLAKE_FILE="${1:-flake.nix}"
DRY_RUN="${DRY_RUN:-false}"

if [[ ! -f "$FLAKE_FILE" ]]; then
  echo "Error: $FLAKE_FILE not found"
  exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Rate limiting for GitHub API
GITHUB_DELAY=0.5
github_api() {
  sleep "$GITHUB_DELAY"
  curl -sf -H "Accept: application/vnd.github.v3+json" "$1" 2>/dev/null
}

# Get latest tag for a repo (sorted by semver)
get_latest_tag() {
  local owner=$1 repo=$2
  local tags
  tags=$(github_api "https://api.github.com/repos/$owner/$repo/tags" | jq -r '.[].name' 2>/dev/null) || return 1

  if [[ -z "$tags" ]]; then
    return 1
  fi

  # Sort by semver (handles v1.0.0, 1.0.0, etc.)
  echo "$tags" | sort -V | tail -1
}

# Get latest commit on default branch
get_latest_commit() {
  local owner=$1 repo=$2 branch=${3:-}

  # Try to get default branch if not specified
  if [[ -z "$branch" ]]; then
    branch=$(github_api "https://api.github.com/repos/$owner/$repo" | jq -r '.default_branch' 2>/dev/null) || branch="main"
  fi

  github_api "https://api.github.com/repos/$owner/$repo/commits/$branch" | jq -r '.sha' 2>/dev/null
}

# Parse GitHub URL to get owner/repo
parse_github_url() {
  local url=$1
  # Handle: github:owner/repo, github:owner/repo?ref=..., github:owner/repo?rev=...
  echo "$url" | sed -E 's|github:([^/?]+)/([^/?]+).*|\1/\2|'
}

# Extract current pin from URL
get_current_pin() {
  local url=$1
  if [[ "$url" =~ \?ref=([^\"]+) ]]; then
    echo "tag:${BASH_REMATCH[1]}"
  elif [[ "$url" =~ \?rev=([^\"]+) ]]; then
    echo "rev:${BASH_REMATCH[1]}"
  elif [[ "$url" =~ github:[^/]+/[^/]+/([^/?\"]+)$ ]]; then
    # Has third path component: github:owner/repo/branch-or-tag
    local branch="${BASH_REMATCH[1]}"
    if [[ "$branch" =~ ^(master|main)$ ]]; then
      echo "unpinned"
    else
      echo "branch:$branch"
    fi
  else
    # Just github:owner/repo - unpinned
    echo "unpinned"
  fi
}

# Update URL with new pin
update_url() {
  local url=$1 pin_type=$2 new_value=$3

  case "$pin_type" in
    tag)
      # Replace ?ref=old with ?ref=new, or add ?ref=new
      if [[ "$url" =~ \?ref= ]]; then
        echo "$url" | sed -E "s|\?ref=[^\"]+|\?ref=$new_value|"
      else
        echo "${url}?ref=$new_value"
      fi
      ;;
    rev)
      # Replace ?rev=old with ?rev=new, or add ?rev=new
      if [[ "$url" =~ \?rev= ]]; then
        echo "$url" | sed -E "s|\?rev=[^\"]+|\?rev=$new_value|"
      else
        echo "${url}?rev=$new_value"
      fi
      ;;
  esac
}

# Track unpinned inputs for nix flake update
UNPINNED_INPUTS=()
UPDATED_COUNT=0

log_info "Scanning $FLAKE_FILE for pinned inputs..."
echo

# Read file content upfront so in-place sed edits don't break the loop
FLAKE_CONTENT=$(< "$FLAKE_FILE")

# Extract all github URLs from flake.nix
while IFS= read -r line; do
  # Match lines with github: URLs
  if [[ "$line" =~ url[[:space:]]*=[[:space:]]*\"(github:[^\"]+)\" ]]; then
    url="${BASH_REMATCH[1]}"
    owner_repo=$(parse_github_url "$url")
    owner="${owner_repo%/*}"
    repo="${owner_repo#*/}"

    pin_info=$(get_current_pin "$url")
    pin_type="${pin_info%%:*}"
    pin_value="${pin_info#*:}"

    case "$pin_type" in
      tag)
        log_info "Checking $owner/$repo (tagged: $pin_value)"
        latest_tag=$(get_latest_tag "$owner" "$repo") || { log_warn "  Could not fetch tags"; continue; }

        if [[ -z "$latest_tag" || "$latest_tag" == "null" ]]; then
          log_warn "  Could not fetch latest tag (rate limited?)"
          continue
        fi

        if [[ "$latest_tag" != "$pin_value" ]]; then
          log_success "  Update available: $pin_value -> $latest_tag"
          if [[ "$DRY_RUN" != "true" ]]; then
            new_url=$(update_url "$url" "tag" "$latest_tag")
            sed -i "s|$url|$new_url|g" "$FLAKE_FILE"
            UPDATED_COUNT=$((UPDATED_COUNT + 1))
          fi
        else
          echo "  Already at latest tag"
        fi
        ;;

      rev)
        log_info "Checking $owner/$repo (commit: ${pin_value:0:7})"
        latest_commit=$(get_latest_commit "$owner" "$repo") || { log_warn "  Could not fetch commits"; continue; }

        if [[ -z "$latest_commit" || "$latest_commit" == "null" ]]; then
          log_warn "  Could not fetch latest commit (rate limited?)"
          continue
        fi

        if [[ "$latest_commit" != "$pin_value" ]]; then
          log_success "  Update available: ${pin_value:0:7} -> ${latest_commit:0:7}"
          if [[ "$DRY_RUN" != "true" ]]; then
            new_url=$(update_url "$url" "rev" "$latest_commit")
            sed -i "s|$url|$new_url|g" "$FLAKE_FILE"
            UPDATED_COUNT=$((UPDATED_COUNT + 1))
          fi
        else
          echo "  Already at latest commit"
        fi
        ;;

      branch)
        log_info "Checking $owner/$repo (pinned: $pin_value)"
        # Check if it looks like a version tag (starts with v or is semver-like)
        if [[ "$pin_value" =~ ^v?[0-9]+\.[0-9]+ ]]; then
          # Likely a tag, check for updates
          latest_tag=$(get_latest_tag "$owner" "$repo") || { log_warn "  Could not fetch tags"; continue; }
          if [[ -z "$latest_tag" || "$latest_tag" == "null" ]]; then
            log_warn "  Could not fetch latest tag (rate limited?)"
            continue
          fi
          if [[ "$latest_tag" != "$pin_value" ]]; then
            log_success "  Update available: $pin_value -> $latest_tag (convert to ?ref= format)"
          else
            echo "  Already at latest tag"
          fi
        else
          echo "  Skipping - branch pin, manage manually"
        fi
        ;;

      unpinned)
        log_info "Found unpinned: $owner/$repo"
        # Extract input name from context (look backwards for the input name)
        UNPINNED_INPUTS+=("$owner/$repo")
        ;;
    esac
  fi
done <<< "$FLAKE_CONTENT"

echo
log_info "Summary:"
echo "  - Updated $UPDATED_COUNT pinned inputs"
echo "  - Found ${#UNPINNED_INPUTS[@]} unpinned inputs"

if [[ ${#UNPINNED_INPUTS[@]} -gt 0 && "$DRY_RUN" != "true" ]]; then
  echo
  log_info "Running nix flake update for unpinned inputs..."
  nix flake update 2>&1 | grep -E "^(updating|Updated)" || true
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo
  log_warn "Dry run - no changes made. Run without DRY_RUN=true to apply."
fi

echo
log_success "Done!"
