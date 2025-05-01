#!/usr/bin/env bash
# Script to update Node package definitions in node.nix to their latest versions

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PKG_FILE="../home-manager/common/node.nix"
FULL_PKG_PATH="$SCRIPT_DIR/$PKG_FILE"

echo "🔍 Extracting current Node packages from $PKG_FILE..."

# Extract package names and versions from the Nix file
# This extracts lines with name = "package-name" and corresponding version = "x.y.z"
# Ignore commented out lines (those with # before name =)
PACKAGES=$(grep -E 'name = "[@a-zA-Z0-9_/-]+' "$FULL_PKG_PATH" | grep -v '^\s*#' | sed -E 's/.*name = "([^"]+)".*/\1/')

if [ -z "$PACKAGES" ]; then
  echo "❌ Error: No packages found in $PKG_FILE"
  exit 1
fi

echo "📋 Found packages:"
echo "$PACKAGES" | tr ' ' '\n'

# Create a working directory
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

# Function to compare version strings
version_gt() {
  test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"
}

# Process each package individually to update or add it
for pkg in $PACKAGES; do
  echo "🔄 Processing $pkg..."
  
  # Get the latest version information from npm registry
  echo "   Fetching latest version from npm registry..."
  NPM_INFO=$(curl -s "https://registry.npmjs.org/$pkg/latest")
  
  # Check if we got a valid response
  if ! echo "$NPM_INFO" | jq -e . >/dev/null 2>&1 && [[ "$NPM_INFO" == *"Not Found"* || "$NPM_INFO" == *"error"* ]]; then
    echo "⚠️ Warning: Could not fetch info for $pkg from npm registry, skipping."
    continue
  fi
  
  # Extract the latest version
  NEW_VERSION=$(echo "$NPM_INFO" | grep -o '"version":"[^"]*"' | head -1 | cut -d'"' -f4)
  
  if [ -z "$NEW_VERSION" ]; then
    echo "⚠️ Warning: Could not determine latest version for $pkg, skipping."
    continue
  fi
  
  # Extract the current version from the original file
  # Find the section for this package
  START_LINE=$(grep -n "name = \"$pkg\";" "$FULL_PKG_PATH" | grep -v '^\s*#' | cut -d':' -f1)
  
  if [ -z "$START_LINE" ]; then
    echo "⚠️ Warning: Package $pkg not found in $PKG_FILE, skipping."
    continue
  fi
  
  # Look for version string in the next 5 lines
  END_SEARCH=$((START_LINE + 5))
  OLD_VERSION=$(sed -n "${START_LINE},${END_SEARCH}p" "$FULL_PKG_PATH" | grep -E 'version = "[^"]+"' | head -1 | sed -E 's/.*version = "([^"]+)".*/\1/')
  
  # Check if OLD_VERSION is empty and set a default value
  if [ -z "$OLD_VERSION" ]; then
    echo "⚠️ Warning: Could not determine current version for $pkg, skipping."
    continue
  fi
  
  # Compare versions - only proceed if new version is greater
  if ! version_gt "$NEW_VERSION" "$OLD_VERSION"; then
    echo "   No upgrade available. Current: $OLD_VERSION, Available: $NEW_VERSION. Skipping."
    continue
  fi
  
  echo "   Updating $pkg from $OLD_VERSION to $NEW_VERSION"
  
  # Construct the npm tarball URL
  # For scoped packages: @scope/pkg -> @scope/pkg/-/pkg-version.tgz
  # For regular packages: pkg -> pkg/-/pkg-version.tgz
  if [[ "$pkg" == @*/* ]]; then
    # It's a scoped package
    SCOPE=$(echo "$pkg" | cut -d'/' -f1)
    NAME=$(echo "$pkg" | cut -d'/' -f2)
    PKG_URL="https://registry.npmjs.org/$pkg/-/$NAME-$NEW_VERSION.tgz"
  else
    # Regular package
    PKG_URL="https://registry.npmjs.org/$pkg/-/$pkg-$NEW_VERSION.tgz"
  fi
  
  # Get SHA256 hash
  echo "   Calculating SHA256 hash for new version..."
  SHA256=""
  if command -v nix-prefetch-url >/dev/null 2>&1; then
    SHA256=$(nix-prefetch-url --quiet "$PKG_URL" 2>/dev/null)
    
    # Convert to base64 format if nix hash command is available
    if [ -n "$SHA256" ] && command -v nix hash >/dev/null 2>&1; then
      SHA256="sha256-$(nix hash convert --hash-algo sha256 --to sri "$SHA256" | cut -d- -f2)"
    fi
  fi
  
  if [ -z "$SHA256" ]; then
    echo "⚠️ Warning: Could not fetch SHA256 hash for $pkg, skipping."
    continue
  fi
  
  # Find the package block start and end
  # Use exact package name match with word boundaries instead of regex patterns
  # First find the line with the package name
  PKG_LINE=$(grep -n "name = \"$pkg\";" "$FULL_PKG_PATH" | grep -v '^\s*#' | head -1 | cut -d':' -f1)
  
  if [ -z "$PKG_LINE" ]; then
    echo "⚠️ Warning: Could not find line with package name: $pkg, skipping."
    continue
  fi
  
  # Now search backwards for the buildNpmPackage line
  PKG_START_LINE=$PKG_LINE
  while [ $PKG_START_LINE -gt 1 ]; do
    PKG_START_LINE=$((PKG_START_LINE - 1))
    LINE=$(sed -n "${PKG_START_LINE}p" "$FULL_PKG_PATH")
    if [[ "$LINE" =~ "buildNpmPackage" ]]; then
      break
    fi
  done
  
  if [ $PKG_START_LINE -le 1 ]; then
    echo "⚠️ Warning: Could not find start of package block for $pkg, skipping."
    continue
  fi
  
  # Find end of package block (next closing parenthesis after the start line)
  # Search for the closing parenthesis (}) at the beginning of a line 
  # followed by another ) character
  END_LINE=$PKG_LINE
  MAX_SEARCH_LINES=50  # Limit how far we search to avoid going too far
  LINES_SEARCHED=0
  
  while [ $LINES_SEARCHED -lt $MAX_SEARCH_LINES ]; do
    END_LINE=$((END_LINE + 1))
    LINES_SEARCHED=$((LINES_SEARCHED + 1))
    LINE=$(sed -n "${END_LINE}p" "$FULL_PKG_PATH")
    if [[ "$LINE" =~ ^[[:space:]]*\}[[:space:]]*\)[[:space:]]*$ ]]; then
      break
    fi
    if [ $END_LINE -ge $(wc -l < "$FULL_PKG_PATH") ]; then
      break
    fi
  done
  
  if [ $LINES_SEARCHED -ge $MAX_SEARCH_LINES ]; then
    echo "⚠️ Warning: Could not find end of package block within reasonable distance for $pkg, skipping."
    continue
  fi
  
  # Create a temporary file
  TEMP_FILE="$WORK_DIR/temp_file.nix"
  
  # Update the version and SHA256 hash
  head -n $((PKG_START_LINE - 1)) "$FULL_PKG_PATH" > "$TEMP_FILE"
  
  # Get the section to modify
  SECTION=$(sed -n "${PKG_START_LINE},${END_LINE}p" "$FULL_PKG_PATH")
  
  # Update version and sha256 using @ as delimiter to avoid conflicts with URL slashes
  UPDATED_SECTION=$(echo "$SECTION" | 
    sed -E "s@(version = \")[^\"]+(\";)@\1${NEW_VERSION}\2@" | 
    sed -E "s@(sha256 = \")[^\"]+(\";)@\1${SHA256}\2@")
  
  echo "$UPDATED_SECTION" >> "$TEMP_FILE"
  tail -n +$((END_LINE + 1)) "$FULL_PKG_PATH" >> "$TEMP_FILE"
  
  # Replace the original file
  mv "$TEMP_FILE" "$FULL_PKG_PATH"
  
  echo "   ✅ Successfully updated $pkg"
done

# Run lint using just command
just lint

echo "✅ Successfully updated packages in $PKG_FILE with latest versions"
git add "$FULL_PKG_PATH"
