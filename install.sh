#!/bin/bash

# Define variables
SCRIPT_NAME="x1check.sh"
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
echo "Downloading $SCRIPT_NAME..."
curl -o $SCRIPT_NAME "$GITHUB_REPO_URL/$SCRIPT_NAME"

# Make the script executable
echo "Setting executable permissions for $SCRIPT_NAME..."
chmod +x $SCRIPT_NAME

# Move to /usr/local/bin for global access (optional)
echo "Moving $SCRIPT_NAME to /usr/local/bin as 'x1check' for easy access..."
sudo mv $SCRIPT_NAME /usr/local/bin/x1check

echo "Installation complete! You can now run the script with 'x1check'."
