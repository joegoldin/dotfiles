#!/usr/bin/env bash
# Script to update Python package definitions in custom-pypi-packages.nix to their latest versions

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PKG_FILE="../home-manager/common/python/custom-pypi-packages.nix"
FULL_PKG_PATH="$SCRIPT_DIR/$PKG_FILE"

echo "🔍 Extracting current Python packages from $PKG_FILE..."

# Extract package names from the Nix file
# Look for lines like "package-name = pythonBase.pkgs.buildPythonPackage" and extract package-name
PACKAGES=$(grep -E '^\s+[a-zA-Z0-9_-]+ = pythonBase\.pkgs\.buildPythonPackage' "$FULL_PKG_PATH" | sed -E 's/^\s+([a-zA-Z0-9_-]+) =.*/\1/' | tr '-' '_')

if [ -z "$PACKAGES" ]; then
  echo "❌ Error: No packages found in $PKG_FILE"
  exit 1
fi

echo "📋 Found packages:"
echo "$PACKAGES" | tr ' ' '\n'

# Create a working directory
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

# Make sure setup-python-packages.sh can be executed
chmod +x "$SCRIPT_DIR/setup-python-packages.sh"

# Function to compare version strings
version_gt() {
  test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"
}

# Process each package individually to update or add it
for pkg in $PACKAGES; do
  echo "🔄 Processing $pkg..."
  
  # Create temp directory for this package
  PKG_TEMP_DIR="$WORK_DIR/$pkg"
  mkdir -p "$PKG_TEMP_DIR"
  
  # Create a virtual environment for this package
  python3 -m venv "$PKG_TEMP_DIR/venv"
  source "$PKG_TEMP_DIR/venv/bin/activate"
  
  # Install the package to get its latest version
  pip install "$pkg" >/dev/null 2>&1 || {
    echo "⚠️ Warning: Could not install $pkg, skipping."
    deactivate
    continue
  }
  
  # Get the version of the installed package
  NEW_VERSION=$(pip show "$pkg" | grep "^Version:" | cut -d ' ' -f 2)
  
  # Extract the current version from the original file with improved pattern matching
  # Get the normalized package name for file searching
  PKG_NORMALIZED=$(echo "$pkg" | tr '_' '-')
  
  # Find the correct section in the file and extract version
  START_LINE=$(grep -n "^\s*${PKG_NORMALIZED}\s*=" "$FULL_PKG_PATH" | cut -d':' -f1)
  if [ -z "$START_LINE" ]; then
    echo "⚠️ Warning: Package $pkg ($PKG_NORMALIZED) not found in $PKG_FILE, skipping."
    deactivate
    continue
  fi
  
  # Look for version string in the next 10 lines
  END_SEARCH=$((START_LINE + 10))
  OLD_VERSION=$(sed -n "${START_LINE},${END_SEARCH}p" "$FULL_PKG_PATH" | grep -E 'version = "[^"]+"' | head -1 | sed -E 's/.*version = "([^"]+)".*/\1/')
  
  # Check if OLD_VERSION is empty and set a default value
  if [ -z "$OLD_VERSION" ]; then
    echo "⚠️ Warning: Could not determine current version for $pkg, skipping."
    deactivate
    continue
  fi
  
  # Compare versions - only proceed if new version is greater
  if ! version_gt "$NEW_VERSION" "$OLD_VERSION"; then
    echo "   No upgrade available. Current: $OLD_VERSION, Available: $NEW_VERSION. Skipping."
    deactivate
    continue
  fi
  
  echo "   Updating $pkg from $OLD_VERSION to $NEW_VERSION"
  
  # Get package information
  PKG_INFO_FILE="$PKG_TEMP_DIR/pkg_info.txt"
  pip show "$pkg" > "$PKG_INFO_FILE"
  
  # Get package URL
  PKG_FIRST_CHAR="${pkg:0:1}"
  PKG_URL="https://files.pythonhosted.org/packages/source/${PKG_FIRST_CHAR}/${pkg}/${pkg}-${NEW_VERSION}.tar.gz"
  
  # Try alternate URL formats if needed
  ALT_PKG_URL="https://files.pythonhosted.org/packages/source/${PKG_FIRST_CHAR}/${PKG_NORMALIZED}/${PKG_NORMALIZED}-${NEW_VERSION}.tar.gz"
  
  # Get SHA256 hash
  SHA256=""
  if command -v nix-prefetch-url >/dev/null 2>&1; then
    # Try primary URL
    SHA256=$(nix-prefetch-url --quiet "$PKG_URL" 2>/dev/null)
    
    # If that fails, try alternate URL
    if [ -z "$SHA256" ]; then
      SHA256=$(nix-prefetch-url --quiet "$ALT_PKG_URL" 2>/dev/null)
      if [ -n "$SHA256" ]; then
        PKG_URL="$ALT_PKG_URL"
      fi
    fi
    
    # Convert to base64 format if nix hash command is available
    if [ -n "$SHA256" ] && command -v nix hash >/dev/null 2>&1; then
      SHA256="sha256-$(nix hash convert --hash-algo sha256 --to sri "$SHA256" | cut -d- -f2)"
    fi
  fi
  
  if [ -z "$SHA256" ]; then
    echo "⚠️ Warning: Could not fetch SHA256 hash for $pkg, skipping."
    deactivate
    continue
  fi
  
  # Find end of package definition
  END_LINE=$(tail -n +"$START_LINE" "$FULL_PKG_PATH" | grep -n "^    };" | head -1 | cut -d':' -f1)
  END_LINE=$((START_LINE + END_LINE - 1))
  
  # Create a temporary file
  TEMP_FILE="$WORK_DIR/temp_file.nix"
  
  # Update the version and SHA256 hash
  head -n $((START_LINE - 1)) "$FULL_PKG_PATH" > "$TEMP_FILE"
  
  # Get the section to modify
  SECTION=$(sed -n "${START_LINE},${END_LINE}p" "$FULL_PKG_PATH")
  
  # Update version, URL, and sha256 using @ as delimiter to avoid conflicts with URL slashes
  UPDATED_SECTION=$(echo "$SECTION" | 
    sed -E "s@(version = \")[^\"]+(\";)@\1${NEW_VERSION}\2@" | 
    sed -E "s@(url = \")[^\"]+(\";)@\1${PKG_URL}\2@" | 
    sed -E "s@(sha256 = \")[^\"]+(\";)@\1${SHA256}\2@")
  
  echo "$UPDATED_SECTION" >> "$TEMP_FILE"
  tail -n +$((END_LINE + 1)) "$FULL_PKG_PATH" >> "$TEMP_FILE"
  
  # Replace the original file
  mv "$TEMP_FILE" "$FULL_PKG_PATH"
  
  # Clean up for this package
  deactivate
  echo "   ✅ Successfully updated $pkg"
done

echo "✅ Successfully updated packages in $PKG_FILE with latest versions"
git add "$FULL_PKG_PATH"

# Automatically build the updated configuration
echo "🔨 Building updated configuration..."
cd "$SCRIPT_DIR/.."
JUST_YES=true just build --fast

# If build succeeded, commit and push changes
if [ $? -eq 0 ]; then
  echo "✅ Build completed successfully!"
  
  git commit -m "Update Python packages to latest versions"
  echo "✅ Changes committed!"
  
  git push
  echo "✅ Changes pushed!"
else
  echo "❌ Build failed. Changes are not committed."
fi

echo "Done! 🎉"
