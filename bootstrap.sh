#!/usr/bin/env bash
# GitHub codespaces setup - prevent redundant runs.

# Check if script has already run
flag_file="/opt/.codespaces_setup_complete"
log_file="~/install.log"
touch $log_file
if [ -f /opt/.codespaces_setup_complete ]; then
    echo "This script has already been run. Exiting..."
    echo "$(date +"%Y-%m-%d %T")" >> "$log_file"
    echo '==========INSTALLATION ABORTED============' >> "$log_file"
    exit 0
fi

# Create log file and write header
echo "This script has not been run. Starting installer script..."
echo '==========RUNNING INSTALLER SCRIPT============' >> "$log_file"
echo "$(date +"%Y-%m-%d %T")" >> "$log_file"

/bin/fish bootstrap.fish
