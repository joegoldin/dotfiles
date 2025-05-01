#!/usr/bin/env bash
# Script to update Node package definitions in node.nix to their latest versions

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PKG_FILE="../home-manager/common/node.nix"
FULL_PKG_PATH="$SCRIPT_DIR/$PKG_FILE"

echo "🔍 Extracting current Node packages from $PKG_FILE..."

# Extract package names and versions from the Nix file
# This extracts packages from the npmPackages array in the new format
# Ignore commented out lines and the unified-node-environment
PACKAGES=$(grep -E '\s+name = "[@a-zA-Z0-9_/-]+";' "$FULL_PKG_PATH" | grep -v '^\s*#' | sed -E 's/.*name = "([^"]+)";.*/\1/' | grep -v 'unified-node-environment')

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
  # Find the package in the npmPackages array
  PKG_BLOCK_START=$(grep -n "name = \"$pkg\";" "$FULL_PKG_PATH" | grep -v '^\s*#' | head -1 | cut -d':' -f1)
  
  if [ -z "$PKG_BLOCK_START" ]; then
    echo "⚠️ Warning: Package $pkg not found in $PKG_FILE, skipping."
    continue
  fi
  
  # Look for version string in the surrounding lines
  PKG_BLOCK_END=$((PKG_BLOCK_START + 10))
  OLD_VERSION=$(sed -n "${PKG_BLOCK_START},${PKG_BLOCK_END}p" "$FULL_PKG_PATH" | grep -E 'version = "[^"]+"' | head -1 | sed -E 's/.*version = "([^"]+)".*/\1/')
  
  # Check if OLD_VERSION is empty
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
  
  # Find the beginning and end of the package block
  # Search for the opening { before the package name line
  BLOCK_START=$PKG_BLOCK_START
  while [ $BLOCK_START -gt 1 ]; do
    BLOCK_START=$((BLOCK_START - 1))
    LINE=$(sed -n "${BLOCK_START}p" "$FULL_PKG_PATH")
    if [[ "$LINE" =~ \{$ ]]; then
      break
    fi
  done
  
  if [ $BLOCK_START -le 1 ]; then
    echo "⚠️ Warning: Could not find start of package block for $pkg, skipping."
    continue
  fi
  
  # Find the end of the package block (next closing brace)
  BLOCK_END=$PKG_BLOCK_START
  MAX_SEARCH_LINES=20
  LINES_SEARCHED=0
  
  while [ $LINES_SEARCHED -lt $MAX_SEARCH_LINES ]; do
    BLOCK_END=$((BLOCK_END + 1))
    LINES_SEARCHED=$((LINES_SEARCHED + 1))
    LINE=$(sed -n "${BLOCK_END}p" "$FULL_PKG_PATH")
    # Look for a line that contains a closing brace, possibly followed by other characters
    if [[ "$LINE" =~ ^\s*\} ]]; then
      break
    fi
    if [ $BLOCK_END -ge $(wc -l < "$FULL_PKG_PATH") ]; then
      break
    fi
  done
  
  # If we couldn't find the end in a reasonable number of lines, increase the search range
  if [ $LINES_SEARCHED -ge $MAX_SEARCH_LINES ]; then
    # Try with a larger search range
    MAX_SEARCH_LINES=50
    LINES_SEARCHED=0
    BLOCK_END=$PKG_BLOCK_START
    
    while [ $LINES_SEARCHED -lt $MAX_SEARCH_LINES ]; do
      BLOCK_END=$((BLOCK_END + 1))
      LINES_SEARCHED=$((LINES_SEARCHED + 1))
      LINE=$(sed -n "${BLOCK_END}p" "$FULL_PKG_PATH")
      # More permissive regex - look for any line containing a closing brace
      if [[ "$LINE" =~ \} ]]; then
        echo "   Found end of block with extended search"
        break
      fi
      if [ $BLOCK_END -ge $(wc -l < "$FULL_PKG_PATH") ]; then
        break
      fi
    done
  fi
  
  if [ $LINES_SEARCHED -ge $MAX_SEARCH_LINES ]; then
    echo "⚠️ Warning: Could not find end of package block within reasonable distance for $pkg, skipping."
    continue
  fi
  
  # Create a temporary file
  TEMP_FILE="$WORK_DIR/temp_file.nix"
  
  # Update the version and SHA256 hash
  head -n $((BLOCK_START - 1)) "$FULL_PKG_PATH" > "$TEMP_FILE"
  
  # Get the section to modify
  SECTION=$(sed -n "${BLOCK_START},${BLOCK_END}p" "$FULL_PKG_PATH")
  
  # Update version and sha256 using @ as delimiter to avoid conflicts with URL slashes
  UPDATED_SECTION=$(echo "$SECTION" | 
    sed -E "s@(version = \")[^\"]+(\";)@\1${NEW_VERSION}\2@" | 
    sed -E "s@(sha256 = \")[^\"]+(\";)@\1${SHA256}\2@")
  
  echo "$UPDATED_SECTION" >> "$TEMP_FILE"
  tail -n +$((BLOCK_END + 1)) "$FULL_PKG_PATH" >> "$TEMP_FILE"
  
  # Replace the original file
  mv "$TEMP_FILE" "$FULL_PKG_PATH"
  
  echo "   ✅ Successfully updated $pkg"
done

# Run lint using just command
just lint

echo "✅ Successfully updated packages in $PKG_FILE with latest versions"
git add "$FULL_PKG_PATH"
