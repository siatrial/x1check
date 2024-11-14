#!/bin/bash

# Set the RPC endpoint for the network (using the correct X1 network endpoint)
network_rpc="http://xolana.xen.network:8899"  # Replace this if your endpoint changes

# Define the folders to check for JSON files (only root of agave-xolana and .config/solana)
folders=("$HOME/.config/solana" "$HOME/agave-xolana")

# Function to display the options
function display_menu() {
    echo -e "\nChoose an option:"
    echo -e "Press Enter to perform a full test."
    echo -e "Press 'b' to only do a balance check."
    echo -e "Press 's' to only do a speed test."
    echo -e "Press 'L' to only check logs for errors."
    echo -e "Press 'n' to only do a network check."
    echo -e "Press 'q' to quit."
    echo -n "Your choice: "
}

# Function to perform a balance check
function balance_check() {
    echo -e "\nJSON Files Public Key and Balance Information:"
    for folder in "${folders[@]}"; do
        if [ -d "$folder" ]; then
            json_files=$(find "$folder" -maxdepth 1 -type f -name "*.json" 2>/dev/null)
            if [ -n "$json_files" ]; then
                for json_file in $json_files; do
                    public_key=$(solana-keygen pubkey "$json_file" 2>/dev/null)
                    if [ -n "$public_key" ]; then
                        balance=$(solana balance "$public_key" --url "$network_rpc" 2>/dev/null)
                        echo -e "File: $json_file | Public Key: $public_key | Balance: $balance"
                    else
                        echo -e "File: $json_file | Unable to retrieve public key"
                    fi
                done
            else
                echo -e "No JSON files found in $folder"
            fi
        fi
    done
}

# Function to perform a speed test
function speed_test() {
    echo -e "\n=== Network Speed Test ==="
    if command -v speedtest-cli &> /dev/null; then
        # Capture server info line
        server_info=$(speedtest-cli | grep 'Hosted by')
        echo -e "$server_info"

        # Run speed test and simplify output
        echo -n "Testing download speed................................................................................"
        download_speed=$(speedtest-cli --no-upload | grep 'Download:' | awk '{print $2, $3}')
        echo -e "\nDownload: ${download_speed}"

        echo -n "Testing upload speed......................................................................................................"
        upload_speed=$(speedtest-cli --no-download | grep 'Upload:' | awk '{print $2, $3}')
        echo -e "\nUpload: ${upload_speed}"
    else
        echo -e "speedtest-cli is not installed."
        echo -e "To install it, run: sudo apt install speedtest-cli"
    fi
}

# Function to perform a log check
function log_check() {
    echo -e "\n=== Recent Validator Errors ==="
    log_file="$HOME/agave-xolana/validator.log"
    if [ ! -f "$log_file" ]; then
        log_file=$(find / -type f -name "validator.log" 2>/dev/null | head -n 1)
    fi

    if [ -f "$log_file" ]; then
        recent_errors=$(grep "ERROR" "$log_file" | tail -n 5)
        if [ -n "$recent_errors" ]; then
            echo -e "Log File: $log_file\nRecent Errors:\n$recent_errors"
        else
            echo -e "No recent errors found in the validator logs."
        fi
    else
        echo -e "Validator log file not found."
    fi
}

# Function to perform a network check
function network_check() {
    echo -e "\n=== Network Connectivity ==="
    if curl -s --connect-timeout 5 "$network_rpc" &> /dev/null; then
        echo -e "Network RPC ($network_rpc) is reachable."
    else
        echo -e "Network RPC ($network_rpc) is not reachable."
    fi
}

# Main loop
while true; do
    display_menu
    read -r user_choice

    # Convert user_choice to lowercase to handle case insensitivity
    user_choice=$(echo "$user_choice" | tr '[:upper:]' '[:lower:]')

    case "$user_choice" in
        "")  # Full test
            echo -e "\nPerforming full test..."
            echo -e "\n=== System Uptime ==="
            uptime=$(uptime -p | sed 's/up //')
            echo -e "Uptime: $uptime"

            echo -e "\nUbuntu Version: $(lsb_release -d | awk -F'\t' '{print $2}')"

            if command -v solana &> /dev/null; then
                echo -e "Solana Version: $(solana --version)"
            else
                echo -e "Solana Version: Not installed"
            fi

            echo -e "\nUbuntu Firewall Port Status (Does not check external Firewall):"
            required_ports=(8000:10000 3334 22)
            for port in "${required_ports[@]}"; do
                if sudo ufw status | grep -q "$port"; then
                    echo -e "Port $port is open"
                else
                    echo -e "Port $port is closed"
                fi
            done

            echo -e "\nLooking for installed folders:"
            for folder in "${folders[@]}"; do
                if [ -d "$folder" ]; then
                    echo -e "Folder exists: $folder"
                else
                    echo -e "Folder missing: $folder"
                fi
            done

            if pgrep -f solana-validator &> /dev/null; then
                echo -e "\nValidator Status: Running"
            else
                echo -e "\nValidator Status: Not Running"
            fi

            echo -e "\n=== Disk Usage ==="
            root_partition=$(df -h / | grep '/' | awk '{print $1}')
            echo -e "Partition: $root_partition"
            echo -e "Total: $(df -h / | grep '/' | awk '{print $2}')"
            echo -e "Used: $(df -h / | grep '/' | awk '{print $3}')"
            echo -e "Free: $(df -h / | grep '/' | awk '{print $4}')"

            network_check
            log_check
            balance_check
            ;;
        "b")  # Balance check only
            echo -e "\nPerforming balance check only..."
            balance_check
            ;;
        "s")  # Speed test only
            echo -e "\nPerforming speed test only..."
            speed_test
            ;;
        "l")  # Log check only
            echo -e "\nChecking logs for errors only..."
            log_check
            ;;
        "n")  # Network check only
            echo -e "\nPerforming network check only..."
            network_check
            ;;
        "q")  # Quit
            echo -e "\nExiting the script. Goodbye!"
            break
            ;;
        *)  # Invalid option
            echo -e "\nInvalid option. Please try again."
            ;;
    esac
done
