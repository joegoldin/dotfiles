#!/usr/bin/env fish

# Change to the directory of the script
set DIR (cd (dirname (status -f)); and pwd)
pushd $DIR

# Prompt user for the input block
echo "Enter the information block (end with Ctrl-D):"
set inputBlock ""
while read line
    set inputBlock "$inputBlock"$line"\n"
end

# Extract version and commit using `string match` and `awk` to clean up processing
set versionz (echo "$inputBlock" | string trim | string split '\n' | grep '^Version:' | awk -F': ' '{print $2}')
set commit (echo "$inputBlock" | string trim | string split '\n' | grep '^Commit:' | awk -F': ' '{print $2}')

# Ensure both 'version' and 'commit' are non-empty
if test -z "$versionz"
    echo "Error: 'Version' not found or is empty."
    exit 1
end

if test -z "$commit"
    echo "Error: 'Commit' not found or is empty."
    exit 1
end

# Construct the URL with the provided version and commit
set url "https://cursor.blob.core.windows.net/remote-releases/$versionz-$commit/vscode-reh-linux-x64.tar.gz"

# Print the constructed URL for debugging
echo "Constructed URL: $url"

# Run nix-prefetch-url to get the sha256 hash of the file
set sha256 (nix-prefetch-url "$url")

# Ensure 'sha256' is non-empty
if test -z "$sha256"
    echo "Error: Failed to fetch sha256 or value is empty!"
    exit 1
end

# Define the path to the default.nix to modify
set nix_file "environments/common/pkgs/default.nix"

# Use sed to replace the version, commit, and sha256 in the specified block
# Create a backup with .bak extension before making the changes
sed -i.bak -e "/cursor-server-linux =.*{/,/};/{
    s/version = \".*\";/version = \"$versionz\";/
    s/commit = \".*\";/commit = \"$commit\";/
    s/sha256 = \".*\";/sha256 = \"$sha256\";/
}" "../$nix_file"

echo "Updated $nix_file with cursor-server-linux version: $versionz, commit: $commit, sha256: $sha256"

# Change directories if supplied
cd ..

# Build the project with the build tool
just build

# Add the modified file to git staging area
git add "$nix_file*"

# Commit the changes with a message
git commit -m "Update $nix_file with cursor-server-linux version: $versionz"

# Push the changes to the remote repository
git push origin main

# Restore the previous directory
popd
