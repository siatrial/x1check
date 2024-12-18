#!/bin/bash

# Define variables
MAIN_SCRIPT_NAME="x1check.sh"
STATS_SCRIPT_NAME="x1stats"
GITHUB_REPO_URL="https://raw.githubusercontent.com/siatrial/x1check/main"

# Update package list
echo "Updating package list..."
sudo apt update -y

# Install necessary packages if missing
echo "Checking for required packages..."

# Install speedtest-cli if not installed
if ! command -v speedtest-cli &> /dev/null; then
    echo "Installing speedtest-cli..."
    sudo apt install -y speedtest-cli
fi

# Install jq if not installed (required for JSON handling)
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    sudo apt install -y jq
fi

# Download the main script
echo "Downloading $MAIN_SCRIPT_NAME..."
curl -o $MAIN_SCRIPT_NAME "$GITHUB_REPO_URL/$MAIN_SCRIPT_NAME"

# Download the stats script
echo "Downloading $STATS_SCRIPT_NAME..."
curl -o $STATS_SCRIPT_NAME "$GITHUB_REPO_URL/$STATS_SCRIPT_NAME"

# Make both scripts executable
echo "Setting executable permissions for $MAIN_SCRIPT_NAME and $STATS_SCRIPT_NAME..."
chmod +x $MAIN_SCRIPT_NAME $STATS_SCRIPT_NAME

# Ensure /usr/local/bin exists
if [[ ! -d "/usr/local/bin" ]]; then
    echo "Creating /usr/local/bin directory..."
    sudo mkdir -p /usr/local/bin
fi

# Ensure /usr/local/bin is in PATH
if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
    echo "Adding /usr/local/bin to PATH..."
    echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
    source ~/.bashrc
fi

# Move scripts to /usr/local/bin for global access
echo "Moving $MAIN_SCRIPT_NAME to /usr/local/bin as 'x1check'..."
sudo mv $MAIN_SCRIPT_NAME /usr/local/bin/x1check

echo "Moving $STATS_SCRIPT_NAME to /usr/local/bin as 'x1stats'..."
sudo mv $STATS_SCRIPT_NAME /usr/local/bin/x1stats

echo "Installation complete! You can now run the scripts with 'x1check' and 'x1stats'."
