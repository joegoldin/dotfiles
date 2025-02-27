#!/usr/bin/env bash
# Script to generate Nix package definitions for Python packages
# Usage: ./generate-python-pkg.sh package1 package2 ...

set -e

if [ $# -eq 0 ]; then
  echo "Usage: $0 package1 package2 ..."
  echo "Example: $0 requests numpy pandas"
  exit 1
fi

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Create a virtual environment to work in
echo "Creating Python virtual environment..."
python3 -m venv "$TEMP_DIR/venv"
source "$TEMP_DIR/venv/bin/activate"

# Install pip-tools to help determine dependencies
echo "Installing pip-tools..."
pip install pip-tools >/dev/null 2>&1

# Function to check if URL exists
check_url() {
  if command -v curl &>/dev/null; then
    if curl --output /dev/null --silent --head --fail "$1"; then
      return 0
    else
      return 1
    fi
  elif command -v wget &>/dev/null; then
    if wget --spider "$1" 2>/dev/null; then
      return 0
    else
      return 1
    fi
  else
    echo "Warning: Neither curl nor wget available, skipping URL check"
    return 0
  fi
}

# Function to determine the correct URL for a package
find_package_url() {
  local package=$1
  local version=$2
  
  # Try multiple URL patterns
  local normalized_name=$(echo "$package" | tr '_' '-')
  local first_char="${normalized_name:0:1}"
  
  # Standard URL pattern
  local std_url="https://files.pythonhosted.org/packages/source/${first_char}/${normalized_name}/${normalized_name}-${version}.tar.gz"
  if check_url "$std_url"; then
    echo "$std_url"
    return 0
  fi
  
  # Try with underscores instead of dashes
  local underscore_name=$(echo "$package" | tr '-' '_')
  local first_char_u="${underscore_name:0:1}"
  local us_url="https://files.pythonhosted.org/packages/source/${first_char_u}/${underscore_name}/${underscore_name}-${version}.tar.gz"
  if check_url "$us_url"; then
    echo "$us_url"
    return 0
  fi
  
  # Try PyPI API to get the download URL
  if command -v curl &>/dev/null && command -v jq &>/dev/null; then
    local pypi_url="https://pypi.org/pypi/${package}/${version}/json"
    
    # Get the response and save it for analysis
    local api_response=$(curl -s "$pypi_url")
    
    # Check if the API returned valid JSON
    if echo "$api_response" | jq empty 2>/dev/null; then
      
      # Try to extract sdist URL
      local download_url=$(echo "$api_response" | jq -r '.urls[] | select(.packagetype=="sdist") | .url' | head -1)
      
      if [ -n "$download_url" ]; then
        if check_url "$download_url"; then
          echo "$download_url"
          return 0
        fi
      else
        # Try wheel if sdist is not available
        download_url=$(echo "$api_response" | jq -r '.urls[] | .url' | head -1)
        if [ -n "$download_url" ]; then
          if check_url "$download_url"; then
            echo "$download_url"
            return 0
          fi
        fi
      fi
    fi
  fi
  
  # Try alternative PyPI endpoints
  local alternate_pypi_url="https://pypi.python.org/pypi/${package}/${version}/json"
  if command -v curl &>/dev/null && command -v jq &>/dev/null; then
    local download_url=$(curl -s "$alternate_pypi_url" | jq -r '.urls[] | select(.packagetype=="sdist") | .url' | head -1)
    if [ -n "$download_url" ] && check_url "$download_url"; then
      echo "$download_url"
      return 0
    fi
  fi
  
  # If all else fails, return the standard URL for further processing
  echo "$std_url"
  return 1
}

# Download a file and save it to a specified location
download_file() {
  local url=$1
  local output_file=$2
  
  if command -v curl &>/dev/null; then
    curl -L -s -o "$output_file" "$url" 2>/dev/null
    return $?
  elif command -v wget &>/dev/null; then
    wget -q -O "$output_file" "$url" 2>/dev/null
    return $?
  else
    echo "Error: Neither curl nor wget available"
    return 1
  fi
}

# Direct call to nix-prefetch-url to get the SHA256 hash
nix_prefetch_sha256() {
  local url=$1
  
  if command -v nix-prefetch-url &>/dev/null; then
    # Use --quiet to minimize output
    local result=$(nix-prefetch-url --quiet "$url" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$result" ]; then
      # Convert to base64 format if nix-hash is available
      if command -v nix-hash &>/dev/null; then
        echo "\"sha256-$(nix-hash --type sha256 --to-base64 "$result")\""
        return 0
      else
        echo "\"$result\""
        return 0
      fi
    fi
  fi
  
  return 1
}

# Calculate SHA256 hash of a file
file_sha256() {
  local file=$1
  
  if command -v nix-hash &>/dev/null; then
    # Best option: Use nix-hash directly
    local base64=$(nix-hash --type sha256 --to-base64 "$file")
    echo "\"sha256-$base64\""
    return 0
  elif command -v sha256sum &>/dev/null; then
    # Use sha256sum
    local hex=$(sha256sum "$file" | cut -d ' ' -f 1)
    
    # Try to convert to base64 format
    if command -v basenc &>/dev/null && command -v xxd &>/dev/null; then
      local base64=$(echo -n "$hex" | xxd -r -p | basenc --base64)
      echo "\"sha256-$base64\""
      return 0
    else
      echo "\"$hex\""
      return 0
    fi
  elif command -v shasum &>/dev/null; then
    # Use shasum
    local hex=$(shasum -a 256 "$file" | cut -d ' ' -f 1)
    echo "\"$hex\""
    return 0
  else
    echo "lib.fakeSha256"
    return 1
  fi
}

# Get SHA256 hash with multiple fallbacks
get_sha256() {
  local url=$1
  local hash=""
  
  # Method 1: Try nix-prefetch-url directly
  hash=$(nix_prefetch_sha256 "$url")
  if [ $? -eq 0 ] && [ -n "$hash" ]; then
    echo "$hash"
    return 0
  fi
  
  # Method 2: Download and hash locally
  local temp_file="$TEMP_DIR/package.tgz"
  
  if download_file "$url" "$temp_file"; then
    hash=$(file_sha256 "$temp_file")
    if [ $? -eq 0 ] && [ -n "$hash" ]; then
      echo "$hash"
      return 0
    fi
  fi
  
  # If all methods failed
  echo "lib.fakeSha256"
  return 1
}

# Centralized license detection function - checks a string for license information
check_license_text() {
  local text="$1"
  local lowercase_text=$(echo "$text" | tr '[:upper:]' '[:lower:]')
  
  # Order matters here - more specific matches should come before general ones
  if [[ "$lowercase_text" == *"apache"*"2.0"* || "$lowercase_text" == *"asl"*"2.0"* || "$lowercase_text" == *"apache license"* ]]; then
    echo "licenses.asl20"
    return 0
  elif [[ "$lowercase_text" == *"mit license"* || "$lowercase_text" == *"mit"* ]]; then
    echo "licenses.mit"
    return 0
  elif [[ "$lowercase_text" == *"bsd 3"* || "$lowercase_text" == *"bsd-3"* || "$lowercase_text" == *"bsd three"* || "$lowercase_text" == *"bsd 3-clause"* ]]; then
    echo "licenses.bsd3"
    return 0
  elif [[ "$lowercase_text" == *"bsd 2"* || "$lowercase_text" == *"bsd-2"* || "$lowercase_text" == *"bsd two"* || "$lowercase_text" == *"bsd 2-clause"* ]]; then
    echo "licenses.bsd2"
    return 0
  elif [[ "$lowercase_text" == *"gpl-3"* || "$lowercase_text" == *"gpl 3"* || "$lowercase_text" == *"gnu general public license v3"* ]]; then
    echo "licenses.gpl3"
    return 0
  elif [[ "$lowercase_text" == *"gpl-2"* || "$lowercase_text" == *"gpl 2"* || "$lowercase_text" == *"gnu general public license v2"* ]]; then
    echo "licenses.gpl2"
    return 0
  elif [[ "$lowercase_text" == *"lgpl-3"* || "$lowercase_text" == *"lgpl 3"* || "$lowercase_text" == *"gnu lesser general public license v3"* ]]; then
    echo "licenses.lgpl3"
    return 0
  elif [[ "$lowercase_text" == *"lgpl-2"* || "$lowercase_text" == *"lgpl 2"* || "$lowercase_text" == *"gnu lesser general public license v2"* ]]; then
    echo "licenses.lgpl2"
    return 0
  elif [[ "$lowercase_text" == *"mozilla"* || "$lowercase_text" == *"mpl"* ]]; then
    echo "licenses.mpl20"
    return 0
  elif [[ "$lowercase_text" == *"isc"* ]]; then
    echo "licenses.isc"
    return 0
  elif [[ "$lowercase_text" == *"public domain"* ]]; then
    echo "licenses.publicDomain"
    return 0
  elif [[ "$lowercase_text" == *"unlicense"* ]]; then
    echo "licenses.unlicense"
    return 0
  elif [[ "$lowercase_text" == *"zlib"* ]]; then
    echo "licenses.zlib"
    return 0
  elif [[ "$lowercase_text" == *"agpl"* ]]; then
    echo "licenses.agpl3"
    return 0
  fi
  
  # If no match found, return empty
  return 1
}

# Function to detect package format and required build inputs
detect_package_format() {
  local package_dir=$1
  local extract_dir="$package_dir/extract"
  local source_tarball="$package_dir/source.tgz"
  local format="setuptools"
  local build_inputs=""
  
  mkdir -p "$extract_dir"
  
  # Extract the tarball
  if [ -f "$source_tarball" ]; then
    tar -xzf "$source_tarball" -C "$extract_dir" --strip-components=1 2>/dev/null || true
    
    # Look for packaging files
    if [ -f "$extract_dir/pyproject.toml" ]; then
      format="pyproject"
      build_inputs="    nativeBuildInputs = with pythonBase.pkgs; [
      setuptools
      wheel"
      
      # Check for specific build systems
      if grep -q "poetry" "$extract_dir/pyproject.toml" 2>/dev/null; then
        build_inputs="${build_inputs}
      poetry-core"
      elif grep -q "hatchling" "$extract_dir/pyproject.toml" 2>/dev/null; then
        build_inputs="${build_inputs}
      hatchling"
      elif grep -q "pdm" "$extract_dir/pyproject.toml" 2>/dev/null; then
        build_inputs="${build_inputs}
      pdm-backend"
      elif grep -q "flit" "$extract_dir/pyproject.toml" 2>/dev/null; then
        build_inputs="${build_inputs}
      flit-core"
      elif grep -q "maturin" "$extract_dir/pyproject.toml" 2>/dev/null; then
        build_inputs="${build_inputs}
      maturin"
      elif grep -q "setuptools_scm" "$extract_dir/pyproject.toml" 2>/dev/null; then
        build_inputs="${build_inputs}
      setuptools-scm"
      elif grep -q "setuptools-scm" "$extract_dir/pyproject.toml" 2>/dev/null; then
        build_inputs="${build_inputs}
      setuptools-scm"
      fi
      
      build_inputs="${build_inputs}
    ];"
    else
      # Check for setup.py
      if [ ! -f "$extract_dir/setup.py" ]; then
        # If neither pyproject.toml nor setup.py exist, try a safer option
        format="pyproject"
        build_inputs="    nativeBuildInputs = with pythonBase.pkgs; [
      setuptools
      wheel
    ];"
      fi
    fi
  fi
  
  echo "format=$format"
  echo "build_inputs=$build_inputs"
}

# Function to detect license from package metadata and source files
detect_license() {
  local package_name=$1
  local package_dir=$2
  local extract_dir="$package_dir/extract"
  local license_info=""
  
  # Method 1: Try to get license from PyPI metadata using the API
  if command -v curl &>/dev/null && command -v jq &>/dev/null; then
    local pypi_api_url="https://pypi.org/pypi/${package_name}/json"
    if check_url "$pypi_api_url"; then
      echo "  Checking PyPI API for license information..." >&2
      local api_response=$(curl -s "$pypi_api_url")
      
      # Check if response is valid JSON
      if echo "$api_response" | jq empty 2>/dev/null; then
        # First try classifiers
        local classifier_licenses=$(echo "$api_response" | jq -r '.info.classifiers[]' 2>/dev/null | grep "License" | head -1)
        if [ -n "$classifier_licenses" ]; then
          echo "  Found license in classifiers: $classifier_licenses" >&2
          license_info=$(check_license_text "$classifier_licenses")
          if [ -n "$license_info" ]; then
            echo "$license_info"
            return 0
          fi
        fi
        
        # Then try the license field directly
        local license_field=$(echo "$api_response" | jq -r '.info.license' 2>/dev/null)
        if [ -n "$license_field" ] && [ "$license_field" != "UNKNOWN" ]; then
          echo "  Found license field: $license_field" >&2
          license_info=$(check_license_text "$license_field")
          if [ -n "$license_info" ]; then
            echo "$license_info"
            return 0
          fi
        fi
      else
        echo "  Warning: PyPI API returned invalid JSON" >&2
      fi
    else
      echo "  Warning: PyPI API URL not accessible" >&2
    fi
  fi

  
  # Method 2: Get license from installed package metadata
  local pip_license=$(pip show "$package_name" | grep "License" | cut -d ':' -f 2- | sed 's/^ *//' | head -1)
  if [ -n "$pip_license" ] && [ "$pip_license" != "UNKNOWN" ]; then
    license_info=$(check_license_text "$pip_license")
    if [ -n "$license_info" ]; then
      echo "$license_info"
      return 0
    fi
  fi
  
  # Method 3: Look for LICENSE files in the extracted source
  if [ -d "$extract_dir" ]; then
    # Look for common license files
    for license_file in LICENSE LICENSE.txt LICENSE.md COPYING; do
      if [ -f "$extract_dir/$license_file" ]; then
        # Read the first 1000 characters (enough to identify most licenses)
        local file_content=$(head -c 1000 "$extract_dir/$license_file")
        license_info=$(check_license_text "$file_content")
        if [ -n "$license_info" ]; then
          echo "$license_info"
          return 0
        fi
      fi
    done
    
    # Check pyproject.toml for license info
    if [ -f "$extract_dir/pyproject.toml" ]; then
      local toml_license=$(grep -E "license\s*=" "$extract_dir/pyproject.toml" | head -1 | sed -E 's/.*license\s*=\s*"([^"]+)".*/\1/')
      if [ -n "$toml_license" ]; then
        license_info=$(check_license_text "$toml_license")
        if [ -n "$license_info" ]; then
          echo "$license_info"
          return 0
        fi
      fi
    fi
    
    # Check setup.py for license info
    if [ -f "$extract_dir/setup.py" ]; then
      local setup_license=$(grep -E "license\s*=" "$extract_dir/setup.py" | head -1 | sed -E 's/.*license\s*=\s*"([^"]+)".*/\1/')
      if [ -n "$setup_license" ]; then
        license_info=$(check_license_text "$setup_license")
        if [ -n "$license_info" ]; then
          echo "$license_info"
          return 0
        fi
      fi
    fi
  fi
  
  # Default to MIT with a comment to update
  echo "licenses.mit  # Please verify and update this license"
  return 0
}

# Process each package
for PACKAGE_NAME in "$@"; do
  echo "Processing package: $PACKAGE_NAME"
  
  # Create a separate Python venv for each package to avoid conflicts
  PACKAGE_DIR="$TEMP_DIR/${PACKAGE_NAME}"
  mkdir -p "$PACKAGE_DIR"
  python3 -m venv "$PACKAGE_DIR/venv"
  source "$PACKAGE_DIR/venv/bin/activate"
  
  # Install the package to get its metadata
  echo "  Installing package to extract metadata..."
  pip install "$PACKAGE_NAME" >/dev/null 2>&1 || {
    echo "  Error: Failed to install ${PACKAGE_NAME}. Skipping."
    deactivate
    continue
  }
  
  # Get package information
  VERSION=$(pip show "$PACKAGE_NAME" | grep "^Version:" | cut -d ' ' -f 2)
  echo "  Version: $VERSION"
  
  # Get dependencies
  DEPS=$(pip show "$PACKAGE_NAME" | grep "Requires" | cut -d ':' -f 2- | tr ',' '\n' | sed 's/^ *//' | sort)
  
  # Get description and homepage
  DESCRIPTION=$(pip show "$PACKAGE_NAME" | grep "Summary" | cut -d ':' -f 2- | sed 's/^ *//' | sed 's/"/\\"/g')
  HOMEPAGE=$(pip show "$PACKAGE_NAME" | grep "Home-page" | cut -d ':' -f 2- | sed 's/^ *//' | sed 's/"/\\"/g')
  
  # Find the correct package URL
  echo "  Finding package URL..."
  PACKAGE_URL=$(find_package_url "$PACKAGE_NAME" "$VERSION")
  echo "  Package URL: $PACKAGE_URL"
  URL_STATUS=$?
  
  if [ $URL_STATUS -ne 0 ]; then
    echo "  Warning: Could not verify URL exists: $PACKAGE_URL"
  else
    echo "  URL verified: $PACKAGE_URL"
  fi
  
  # Download the package source to detect format and license
  echo "  Downloading package source for format and license detection..."
  download_file "$PACKAGE_URL" "$PACKAGE_DIR/source.tgz"
  
  # Detect package format
  echo "  Detecting package format..."
  FORMAT_INFO=$(detect_package_format "$PACKAGE_DIR")
  PACKAGE_FORMAT=$(echo "$FORMAT_INFO" | grep "format=" | cut -d= -f2)
  BUILD_INPUTS=$(echo "$FORMAT_INFO" | grep -A10 "build_inputs=" | cut -d= -f2-)
  
  echo "  Package format: $PACKAGE_FORMAT"
  
  # Detect license
  echo "  Detecting license..."
  LICENSE=$(detect_license "$PACKAGE_NAME" "$PACKAGE_DIR")
  echo "  License: $LICENSE"
  
  # Get the SHA256 hash with detailed output to see what's happening
  echo "  Calculating SHA256 hash for $PACKAGE_URL..."
  SHA256=$(get_sha256 "$PACKAGE_URL")
  HASH_STATUS=$?
  
  # Format dependencies for Nix
  NIX_DEPS=""
  if [ -n "$DEPS" ]; then
    for DEP in $DEPS; do
      if [ -n "$DEP" ]; then
        # Convert package name to Nix format (hyphens, lowercase)
        NIX_DEP=$(echo "$DEP" | tr '_' '-' | tr '[:upper:]' '[:lower:]')
        # Add properly indented dependency without \n
        NIX_DEPS="${NIX_DEPS}      ${NIX_DEP}"$'\n'
      fi
    done
  fi
  
  # Generate the Nix package definition
  # Generate the Nix package definition
  CLEANED_PACKAGE_NAME=$(echo "$PACKAGE_NAME" | tr '_' '-')
  cat << EOF > "$PACKAGE_DIR/${PACKAGE_NAME}.nix"
  ${CLEANED_PACKAGE_NAME} = pythonBase.pkgs.buildPythonPackage rec {
    pname = "${CLEANED_PACKAGE_NAME}";
    version = "${VERSION}";
    format = "${PACKAGE_FORMAT}";

    src = pkgs.fetchurl {
      url = "${PACKAGE_URL}";
      sha256 = ${SHA256};
    };

${BUILD_INPUTS:+${BUILD_INPUTS}
}    # Dependencies
    propagatedBuildInputs = with pythonBase.pkgs; [
${NIX_DEPS:-      # No dependencies}
    ];

    # Disable tests - enable if you have specific test dependencies
    doCheck = false;

    # Basic import check
    pythonImportsCheck = [ "${PACKAGE_NAME//-/_}" ];

    meta = with lib; {
      description = "${DESCRIPTION:-Python package: ${PACKAGE_NAME}}";
      homepage = "${HOMEPAGE:-https://pypi.org/project/${PACKAGE_NAME}/}";
      license = ${LICENSE};
    };
  };

EOF
  
  # Deactivate the venv for this package
  deactivate
  
  # Save the output to a file
  cp "$PACKAGE_DIR/${PACKAGE_NAME}.nix" "./${PACKAGE_NAME}-pypi.nix"
done

# Combined definitions
cat $(ls *-pypi.nix) > custom-pypi-packages.nix
rm -rf *-pypi.nix
echo "Combined definitions saved to custom-pypi-packages.nix"

# Final cleanup
echo
echo "Script completed successfully!"
