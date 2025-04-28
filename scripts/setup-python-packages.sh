#!/usr/bin/env bash
# Script to generate Nix package definitions for Python packages
# Usage: ./generate-python-pkg.sh package1 package2 ...

set -e

if [ $# -eq 0 ]; then
  echo "Usage: $0 package1 package2 ..."
  echo "Example: $0 requests numpy pandas"
  exit 1
fi

# Get the script directory and set paths
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PKG_FILE="../home-manager/common/python/custom-pypi-packages.nix"
FULL_PKG_PATH="$SCRIPT_DIR/$PKG_FILE"
DEFAULT_NIX_PATH="$SCRIPT_DIR/../home-manager/common/python/default.nix"

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

# Install all packages at once to ensure version compatibility
echo "Installing all packages to resolve dependencies..."
for FULL_PACKAGE_NAME in "$@"; do
  # Extract base package name (strip extras)
  BASE_PACKAGE_NAME=$(echo "$FULL_PACKAGE_NAME" | sed -E 's/\[.*\]$//')
  
  echo "  Installing $FULL_PACKAGE_NAME..."
  pip install "$FULL_PACKAGE_NAME" || {
    echo "Error: Failed to install ${FULL_PACKAGE_NAME}. Exiting."
    deactivate
    exit 1
  }
done

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
      
      # Try to find Python 3.12 compatible wheel or sdist
      local download_url=""
      
      # For macOS, prioritize wheels with the highest macOS version number
      if [[ "$OSTYPE" == "darwin"* ]]; then
        # Extract all macOS wheel URLs and their versions
        local mac_wheels=$(echo "$api_response" | jq -r '.urls[] | select(.packagetype=="bdist_wheel") | select(.filename | contains("macosx")) | .url')
        local best_url=""
        local best_major=0
        local best_minor=0
        
        while read -r url; do
          if [ -n "$url" ]; then
            # Extract macOS version from filename (e.g., macosx_14_0 -> 14.0)
            if [[ "$url" =~ macosx_([0-9]+)_([0-9]+) ]]; then
              local major="${BASH_REMATCH[1]}"
              local minor="${BASH_REMATCH[2]}"
              
              # Check if this is a Python 3.12 wheel or a universal wheel
              if [[ "$url" =~ cp312 ]] || [[ "$url" =~ py3 ]]; then
                # If it's a higher macOS version, use it
                if [ "$major" -gt "$best_major" ] || ([ "$major" -eq "$best_major" ] && [ "$minor" -gt "$best_minor" ]); then
                  best_major="$major"
                  best_minor="$minor"
                  best_url="$url"
                fi
              fi
            fi
          fi
        done <<< "$mac_wheels"
        
        if [ -n "$best_url" ]; then
          download_url="$best_url"
        fi
      fi
      
      # If not macOS or no macOS wheels found, try to find Python 3.12 specific wheel
      if [ -z "$download_url" ]; then
        download_url=$(echo "$api_response" | jq -r '.urls[] | select(.packagetype=="bdist_wheel") | select(.filename | contains("cp312")) | .url' | head -1)
      fi
      
      # If no Python 3.12 specific wheel, try to find any wheel that's compatible with 3.12
      if [ -z "$download_url" ]; then
        # Look for wheels with py3 tag (compatible with Python 3.x)
        download_url=$(echo "$api_response" | jq -r '.urls[] | select(.packagetype=="bdist_wheel") | select(.python_version | contains("py3")) | .url' | head -1)
      fi
      
      # If no Python 3.12 compatible wheel, look for sdist
      if [ -z "$download_url" ]; then
        download_url=$(echo "$api_response" | jq -r '.urls[] | select(.packagetype=="sdist") | .url' | head -1)
      fi
      
      # If we found a URL, verify it and return it
      if [ -n "$download_url" ]; then
        if check_url "$download_url"; then
          echo "$download_url"
          return 0
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
      # Convert to base64 format if nix hash command is available
      if command -v nix &>/dev/null && nix hash --help &>/dev/null; then
        echo "\"sha256-$(nix hash convert --hash-algo sha256 --to sri "$result" | cut -d- -f2)\""
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
  
  if command -v nix &>/dev/null && nix hash --help &>/dev/null; then
    # Best option: Use new nix hash command
    local sri=$(nix hash file "$file" 2>/dev/null)
    echo "\"$sri\""
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
  local package_url=$2
  local extract_dir="$package_dir/extract"
  local source_tarball="$package_dir/source.tgz"
  local format="setuptools"
  local build_inputs=""
  
  # Check if it's a wheel file
  if [[ "$package_url" == *.whl ]]; then
    format="wheel"
    build_inputs=""  # No build inputs needed for wheel format
    echo "format=$format"
    echo "build_inputs=$build_inputs"
    return 0
  fi
  
  mkdir -p "$extract_dir"
  
  # Extract the tarball
  if [ -f "$source_tarball" ]; then
    if [[ "$package_url" == *.whl ]]; then
      # For wheel files, we don't need to extract
      format="wheel"
      build_inputs=""
    else
      # For tarballs, extract and analyze
      tar -xzf "$source_tarball" -C "$extract_dir" --strip-components=1 2>/dev/null || {
        # If tar fails, it might be a zip file (some packages on PyPI use zip)
        unzip -q "$source_tarball" -d "$extract_dir" 2>/dev/null || true
      }
      
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
        if [ -n "$license_field" ] && [ "$license_field" != "UNKNOWN" ] && [ "$license_field" != "null" ]; then
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

# Function to check if a package already exists in custom-pypi-packages.nix
package_exists() {
  local package_name="$1"
  local cleaned_name=$(echo "$package_name" | tr '_' '-')
  
  if grep -q "    ${cleaned_name} = pythonBase\.pkgs\.buildPythonPackage" "$FULL_PKG_PATH"; then
    return 0  # Package exists
  else
    return 1  # Package doesn't exist
  fi
}

# Check if package is already in default.nix
package_in_default() {
  local package_name="$1"
  local cleaned_name=$(echo "$package_name" | tr '_' '-')
  
  if grep -q "customPackages\.${cleaned_name}" "$DEFAULT_NIX_PATH"; then
    return 0  # Package is in default.nix
  else
    return 1  # Package is not in default.nix
  fi
}

# Array to store all new package definitions
declare -a NEW_PACKAGE_DEFINITIONS
# Array to store package names for default.nix
declare -a PACKAGES_FOR_DEFAULT

# Dictionary to keep track of which packages we're processing
declare -A LOCAL_PACKAGES

# Get all package names to process
for pkg in "$@"; do
  # Extract base package name (strip extras)
  BASE_PKG=$(echo "$pkg" | sed -E 's/\[.*\]$//')
  LOCAL_PACKAGES["$BASE_PKG"]=1
done

# Process each package
for FULL_PACKAGE_NAME in "$@"; do
  echo "Processing package: $FULL_PACKAGE_NAME"
  
  # Extract base package name (without extras) for package info
  BASE_PACKAGE_NAME=$(echo "$FULL_PACKAGE_NAME" | sed -E 's/\[.*\]$//')
  # Extract extras if present
  EXTRAS=$(echo "$FULL_PACKAGE_NAME" | grep -o '\[.*\]' || echo "")
  
  # Check if package already exists
  if package_exists "$BASE_PACKAGE_NAME"; then
    echo "  Package $BASE_PACKAGE_NAME already exists in $PKG_FILE, skipping definition generation."
  else
    # Create a directory for the package
    PACKAGE_DIR="$TEMP_DIR/${BASE_PACKAGE_NAME}"
    mkdir -p "$PACKAGE_DIR"
    
    # Get package information
    VERSION=$(pip show "$BASE_PACKAGE_NAME" | grep "^Version:" | cut -d ' ' -f 2)
    echo "  Version: $VERSION"
    
    # Get dependencies
    DEPS=$(pip show "$BASE_PACKAGE_NAME" | grep "Requires" | cut -d ':' -f 2- | tr ',' '\n' | sed 's/^ *//' | sort)
    
    # Get description and homepage
    DESCRIPTION=$(pip show "$BASE_PACKAGE_NAME" | grep "Summary" | cut -d ':' -f 2- | sed 's/^ *//' | sed 's/"/\\"/g')
    HOMEPAGE=$(pip show "$BASE_PACKAGE_NAME" | grep "Home-page" | cut -d ':' -f 2- | sed 's/^ *//' | sed 's/"/\\"/g')
    
    # Find the correct package URL
    echo "  Finding package URL..."
    PACKAGE_URL=$(find_package_url "$BASE_PACKAGE_NAME" "$VERSION")
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
    FORMAT_INFO=$(detect_package_format "$PACKAGE_DIR" "$PACKAGE_URL")
    PACKAGE_FORMAT=$(echo "$FORMAT_INFO" | grep "format=" | cut -d= -f2)
    BUILD_INPUTS=$(echo "$FORMAT_INFO" | grep -A10 "build_inputs=" | cut -d= -f2-)
    
    echo "  Package format: $PACKAGE_FORMAT"
    
    # Detect license
    echo "  Detecting license..."
    LICENSE=$(detect_license "$BASE_PACKAGE_NAME" "$PACKAGE_DIR")
    echo "  License: $LICENSE"
    
    # Get the SHA256 hash with detailed output to see what's happening
    echo "  Calculating SHA256 hash for $PACKAGE_URL..."
    SHA256=$(get_sha256 "$PACKAGE_URL")
    HASH_STATUS=$?
    
    # Format dependencies for Nix
    NIX_DEPS=""
    INTERNAL_DEPS=""
    EXTERNAL_DEPS=""
    if [ -n "$DEPS" ]; then
      for DEP in $DEPS; do
        if [ -n "$DEP" ]; then
          # Convert package name to Nix format (hyphens, lowercase)
          NIX_DEP=$(echo "$DEP" | tr '_' '-' | tr '[:upper:]' '[:lower:]')
          
          # Check if this is one of our local packages
          if [ "${LOCAL_PACKAGES[$DEP]}" = "1" ]; then
            # Reference local package
            INTERNAL_DEPS="${INTERNAL_DEPS}        pythonPackages.${NIX_DEP}"$'\n'
          else
            # Reference standard nixpkgs package
            EXTERNAL_DEPS="${EXTERNAL_DEPS}        ${NIX_DEP}"$'\n'
          fi
        fi
      done
    fi
    
    # Combine dependencies properly
    if [ -n "$EXTERNAL_DEPS" ] && [ -n "$INTERNAL_DEPS" ]; then
      NIX_DEPS="with pythonBase.pkgs; [
${EXTERNAL_DEPS}      ] ++ [
${INTERNAL_DEPS}      ]"
    elif [ -n "$EXTERNAL_DEPS" ]; then
      NIX_DEPS="with pythonBase.pkgs; [
${EXTERNAL_DEPS}      ]"
    elif [ -n "$INTERNAL_DEPS" ]; then
      NIX_DEPS="[
${INTERNAL_DEPS}      ]"
    else
      NIX_DEPS="[]"
    fi
    
    # Generate the Nix package definition
    CLEANED_PACKAGE_NAME=$(echo "$BASE_PACKAGE_NAME" | tr '_' '-')
    
    # Add the extras if present to the import check
    IMPORT_MODULE="${BASE_PACKAGE_NAME//-/_}"
    
    # Try to determine the correct import module name using importlib.metadata
    echo "  Testing import module name..."
    PYTHON_CODE="
import sys
import importlib.metadata

# Get the mapping of modules to package names
pkg_map = importlib.metadata.packages_distributions()

# Our package name
package_name = \"${BASE_PACKAGE_NAME}\"
package_name_normalized = package_name.lower().replace('-', '_')

# First, look for direct match
for module, packages in pkg_map.items():
    if package_name in packages or package_name.lower() in [p.lower() for p in packages]:
        print(module)
        sys.exit(0)

# If no direct match, try with normalized name
for module, packages in pkg_map.items():
    if any(p.lower().replace('-', '_') == package_name_normalized for p in packages):
        print(module)
        sys.exit(0)

# If still no match, use default
print(\"${IMPORT_MODULE}\")
"
    
    TESTED_IMPORT_MODULE=$(python -c "$PYTHON_CODE" 2>/dev/null || echo "$IMPORT_MODULE")
    echo "  Using import module: $TESTED_IMPORT_MODULE"
    
    PACKAGE_DEF="    ${CLEANED_PACKAGE_NAME} = pythonBase.pkgs.buildPythonPackage rec {
      pname = \"${CLEANED_PACKAGE_NAME}\";
      version = \"${VERSION}\";
      format = \"${PACKAGE_FORMAT}\";${EXTRAS_ATTR}

      src = pkgs.fetchurl {
        url = \"${PACKAGE_URL}\";
        sha256 = ${SHA256};
      };

${BUILD_INPUTS:+${BUILD_INPUTS}
}      # Dependencies
      propagatedBuildInputs = ${NIX_DEPS};

      # Disable tests - enable if you have specific test dependencies
      doCheck = false;

      # Basic import check
      pythonImportsCheck = [ \"${TESTED_IMPORT_MODULE}\" ];

      meta = with lib; {
        description = \"${DESCRIPTION:-Python package: ${PACKAGE_NAME}}\";
        homepage = \"${HOMEPAGE:-https://pypi.org/project/${PACKAGE_NAME}/}\";
        license = ${LICENSE};
      };
    };"
    
    # Add to array of definitions
    NEW_PACKAGE_DEFINITIONS+=("$PACKAGE_DEF")
  fi
  
  # Check if the package needs to be added to default.nix
  # For default.nix we should use the FULL_PACKAGE_NAME
  if ! package_in_default "$BASE_PACKAGE_NAME"; then
    CLEANED_PACKAGE_NAME=$(echo "$BASE_PACKAGE_NAME" | tr '_' '-')
    PACKAGES_FOR_DEFAULT+=("$CLEANED_PACKAGE_NAME")
  else
    echo "  Package $BASE_PACKAGE_NAME already in default.nix, skipping."
  fi
done

# If we have new package definitions, append them to the existing file
if [ ${#NEW_PACKAGE_DEFINITIONS[@]} -gt 0 ]; then
  echo "Adding ${#NEW_PACKAGE_DEFINITIONS[@]} new package definition(s) to $PKG_FILE..."
  
  # Create a temporary file
  TEMP_FILE="$TEMP_DIR/custom-pypi-packages.nix.tmp"
  
  # Find the position to insert new packages (before the closing structure)
  END_POSITION=$(grep -n "^  };" "$FULL_PKG_PATH" | head -1 | cut -d':' -f1)
  
  if [ -z "$END_POSITION" ]; then
    echo "Error: Could not find the end of package definitions in $PKG_FILE"
    exit 1
  fi
  
  # Copy the file up to the insertion point
  head -n $(($END_POSITION - 1)) "$FULL_PKG_PATH" > "$TEMP_FILE"
  
  # Add new package definitions
  for def in "${NEW_PACKAGE_DEFINITIONS[@]}"; do
    echo "$def" >> "$TEMP_FILE"
    echo >> "$TEMP_FILE"
  done
  
  # Add the closing structure
  echo "  };" >> "$TEMP_FILE"
  echo "in" >> "$TEMP_FILE"
  echo "pythonPackages" >> "$TEMP_FILE"
  
  # Replace the original file
  mv "$TEMP_FILE" "$FULL_PKG_PATH"
  echo "Successfully updated $PKG_FILE with new package definitions."
fi

# If we have packages to add to default.nix, update it
if [ ${#PACKAGES_FOR_DEFAULT[@]} -gt 0 ]; then
  echo "Updating default.nix to include ${#PACKAGES_FOR_DEFAULT[@]} new package(s)..."
  
  # Create a temporary file
  TEMP_FILE="$TEMP_DIR/default.nix.tmp"
  
  # Find the start of the custom packages section
  SECTION_START=$(grep -n "# Custom packages from PyPI" "$DEFAULT_NIX_PATH" | head -1 | cut -d':' -f1)
  
  if [ -z "$SECTION_START" ]; then
    echo "Error: Could not find the custom packages section in default.nix"
    exit 1
  fi
  
  # Find the end of the custom packages section (next closing bracket)
  SECTION_END_OFFSET=$(tail -n +$SECTION_START "$DEFAULT_NIX_PATH" | grep -n "      ]" | head -1 | cut -d':' -f1)
  if [ -z "$SECTION_END_OFFSET" ]; then
    echo "Error: Could not find the end of custom packages section"
    exit 1
  fi
  SECTION_END=$((SECTION_START + SECTION_END_OFFSET - 1))
  
  # Extract current custom packages
  CURRENT_PACKAGES=$(sed -n "$((SECTION_START+1)),$((SECTION_END-1))p" "$DEFAULT_NIX_PATH" | grep "customPackages\." | sed 's/^[[:space:]]*customPackages\.\([a-zA-Z0-9_-]\+\).*/\1/')
  
  # Combine current and new packages, then sort them
  ALL_PACKAGES=("$CURRENT_PACKAGES" "${PACKAGES_FOR_DEFAULT[@]}")
  SORTED_PACKAGES=($(echo "${ALL_PACKAGES[@]}" | tr ' ' '\n' | sort -u))
  
  # Write file up to custom packages section
  sed -n "1,$((SECTION_START))p" "$DEFAULT_NIX_PATH" > "$TEMP_FILE"
  
  # Write packages in alphabetical order
  for pkg in "${SORTED_PACKAGES[@]}"; do
    if [ -n "$pkg" ]; then
      echo "        customPackages.${pkg}" >> "$TEMP_FILE"
    fi
  done
  
  # Write rest of file
  sed -n "$((SECTION_END)),\$p" "$DEFAULT_NIX_PATH" >> "$TEMP_FILE"
  
  # Replace the original file
  mv "$TEMP_FILE" "$DEFAULT_NIX_PATH"
  echo "Successfully updated default.nix with new packages in alphabetical order."
fi

# Clean up - deactivate virtual environment
deactivate

just lint

echo
echo "Script completed successfully!"
echo "✅ Added ${#NEW_PACKAGE_DEFINITIONS[@]} new package(s) to custom-pypi-packages.nix"
echo "✅ Added ${#PACKAGES_FOR_DEFAULT[@]} new package(s) to default.nix"

# Git operations if changes were made
if [ ${#NEW_PACKAGE_DEFINITIONS[@]} -gt 0 ] || [ ${#PACKAGES_FOR_DEFAULT[@]} -gt 0 ]; then
  git add "$FULL_PKG_PATH" "$DEFAULT_NIX_PATH"
fi
