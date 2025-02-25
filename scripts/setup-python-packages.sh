#!/usr/bin/env bash
# This script helps get SHA256 hashes for Python packages for use in python.nix

set -e

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 package-name [version]"
    echo "Example: $0 anthropic-bedrock 0.15.0"
    exit 1
fi

PACKAGE_NAME="$1"
VERSION="${2:-latest}"

# Create a temporary directory for working
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
cd "$TEMP_DIR"

echo "Checking package: $PACKAGE_NAME ${VERSION:+version $VERSION}"

# Get package info from PyPI
get_package_info() {
    local pkg="$1"
    local ver="$2"
    local url="https://pypi.org/pypi/${pkg}"
    
    if [ "$ver" != "latest" ]; then
        url="${url}/${ver}"
    fi
    
    url="${url}/json"
    
    if command -v curl &> /dev/null; then
        curl -s "$url"
    elif command -v wget &> /dev/null; then
        wget -q -O - "$url"
    else
        echo "Error: Neither curl nor wget is available"
        exit 1
    fi
}

# Extract information from PyPI JSON response
PYPI_JSON=$(get_package_info "$PACKAGE_NAME" "$VERSION")

if [[ "$PYPI_JSON" == *"Not Found"* ]]; then
    echo "Error: Package $PACKAGE_NAME${VERSION:+ version $VERSION} not found on PyPI"
    exit 1
fi

# Extract version if not specified
if [ "$VERSION" = "latest" ]; then
    if command -v jq &> /dev/null; then
        VERSION=$(echo "$PYPI_JSON" | jq -r '.info.version')
    else
        # Fallback if jq is not available
        VERSION=$(echo "$PYPI_JSON" | grep -o '"version": "[^"]*"' | head -1 | cut -d'"' -f4)
    fi
    echo "Latest version: $VERSION"
fi

# Try to find source distribution URL (sdist)
get_sdist_url() {
    local json="$1"
    
    if command -v jq &> /dev/null; then
        echo "$json" | jq -r '.urls[] | select(.packagetype=="sdist") | .url' | head -1
    else
        # Fallback if jq is not available
        echo "$json" | grep -o '"packagetype": "sdist".*"url": "[^"]*"' | grep -o '"url": "[^"]*"' | cut -d'"' -f4 | head -1
    fi
}

DOWNLOAD_URL=$(get_sdist_url "$PYPI_JSON")

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: Could not find source distribution (sdist) for $PACKAGE_NAME $VERSION"
    echo "This package might only be available as a wheel, which is harder to package with Nix."
    exit 1
fi

echo "Found source distribution URL: $DOWNLOAD_URL"

# Grab the source and calculate SHA256
echo "Fetching package to calculate SHA256..."
if command -v nix-prefetch-url &> /dev/null; then
    SHA256=$(nix-prefetch-url "$DOWNLOAD_URL")
    NIX_HASH_FORMAT="sha256-$(nix-hash --type sha256 --to-base64 "$SHA256")"
else
    # Alternative method if nix-prefetch-url is not available
    if command -v curl &> /dev/null; then
        curl -L -o package.tgz "$DOWNLOAD_URL"
    elif command -v wget &> /dev/null; then
        wget -O package.tgz "$DOWNLOAD_URL"
    else
        echo "Error: Neither curl nor wget is available"
        exit 1
    fi
    
    if command -v shasum &> /dev/null; then
        SHA256=$(shasum -a 256 package.tgz | cut -d' ' -f1)
    elif command -v sha256sum &> /dev/null; then
        SHA256=$(sha256sum package.tgz | cut -d' ' -f1)
    else
        echo "Error: Neither shasum nor sha256sum is available"
        exit 1
    fi
    
    # Convert to Nix base64 format if possible
    if command -v basenc &> /dev/null; then
        BASE64=$(echo -n "$SHA256" | xxd -r -p | basenc --base64)
        NIX_HASH_FORMAT="sha256-$BASE64"
    else
        # Fallback to simple hex format
        NIX_HASH_FORMAT="$SHA256"
    fi
fi

# Output Nix configuration snippet
echo
echo "Add this to the customPipPackages list in python.nix:"
echo
echo "{
  name = \"$PACKAGE_NAME\";
  version = \"$VERSION\";
  sha256 = \"$NIX_HASH_FORMAT\";
}"
echo
