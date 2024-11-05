#!/bin/bash

# Initialize output variable for a clean final report
output=""

# Prompt user to decide if they want to check logs
echo -n "Do you want to check recent validator logs for errors? (y/n): "
read -r check_logs

# Prompt user to decide if they want to perform a speed test
echo -n "Do you want to perform a network speed test? (y/n): "
read -r run_speedtest

# System Uptime
output+="\n=== System Uptime ===\n"
uptime=$(uptime -p | sed 's/up //')
output+="Uptime: $uptime\n"

# Check Ubuntu version
ubuntu_version=$(lsb_release -d | awk -F"\t" '{print $2}')
output+="Ubuntu Version: $ubuntu_version\n"

# Check Solana installation and version
if command -v solana &> /dev/null; then
    solana_version=$(solana --version)
    output+="Solana Version: $solana_version\n"
else
    output+="Solana Version: Not installed\n"
fi

# Check firewall ports
output+="\nUbuntu Firewall Port Status (Does not check external Firewall):\n"
required_ports=(8000:10000 3334 22)
for port in "${required_ports[@]}"; do
    if sudo ufw status | grep -q "$port"; then
        output+="Port $port is open\n"
    else
        output+="Port $port is closed\n"
    fi
done

# Check for necessary folders
output+="\nLooking for installed folders:\n"
folders=("$HOME/.config/solana" "$HOME/xolana" "$HOME/x1_validator")
for folder in "${folders[@]}"; do
    if [ -d "$folder" ]; then
        output+="Folder exists: $folder\n"
    else
        output+="Folder missing: $folder\n"
    fi
done

# Check if the validator is running (overall status)
if pgrep -f solana-validator &> /dev/null; then
    output+="\nValidator Status: Running\n"
else
    output+="\nValidator Status: Not Running\n"
fi

# Check staking status by examining if there are any active stake accounts
staking_active=false
for json_file in $(find "$HOME/.config/solana" "$HOME/x1_validator" -type f -name "*.json" 2>/dev/null); do
    stake_account=$(jq -r '.stakeAccount' "$json_file" 2>/dev/null)
    if [ "$stake_account" != "null" ]; then
        staking_active=true
        break
    fi
done
output+="Staking Status: "
output+=$([ "$staking_active" = true ] && echo "Active" || echo "Inactive")
output+="\n"

# Disk Usage (finds the root partition dynamically)
output+="\n=== Disk Usage ===\n"
root_partition=$(df -h / | grep '/' | awk '{print $1}')
disk_total=$(df -h / | grep '/' | awk '{print $2}')
disk_used=$(df -h / | grep '/' | awk '{print $3}')
disk_free=$(df -h / | grep '/' | awk '{print $4}')
output+="Partition: $root_partition\n"
output+="Total: $disk_total\n"
output+="Used: $disk_used\n"
output+="Free: $disk_free\n"

# Set the RPC endpoint for the network (using the correct X1 network endpoint)
network_rpc="http://xolana.xen.network:8899"  # Replace this if your endpoint changes

# Network Connectivity Check (curl to check the specified network RPC Server)
output+="\n=== Network Connectivity ===\n"
if curl -s --connect-timeout 5 "$network_rpc" &> /dev/null; then
    output+="Network RPC ($network_rpc) is reachable.\n"
else
    output+="Network RPC ($network_rpc) is not reachable.\n"
fi

# Validator Logs Check (Last 5 "ERROR" Entries) - Only if user chose 'y'
if [[ "$check_logs" =~ ^[Yy]$ ]]; then
    output+="\n=== Recent Validator Errors ===\n"
    log_file="/var/log/solana/validator.log"
    if [ ! -f "$log_file" ]; then
        log_file=$(find / -type f -name "validator.log" 2>/dev/null | head -n 1)
    fi

    if [ -f "$log_file" ]; then
        recent_errors=$(grep "ERROR" "$log_file" | tail -n 5)
        if [ -n "$recent_errors" ]; then
            output+="Log File: $log_file\nRecent Errors:\n$recent_errors\n"
        else
            output+="No recent errors found in the validator logs.\n"
        fi
    else
        output+="Validator log file not found.\n"
    fi
else
    output+="\nValidator log check skipped by user.\n"
fi

# Output main report up to this point
echo -e "$output"

# Network Speed Test Section
if [[ "$run_speedtest" =~ ^[Yy]$ ]]; then
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
        # Prompt to install speedtest-cli
        echo -e "speedtest-cli is not installed."
        echo -e "To install it, run: sudo apt install speedtest-cli"
    fi
else
    echo -e "Speed test skipped by user."
fi

# Find JSON files in specified directories and retrieve their public keys and balances
echo -e "\nJSON Files Public Key and Balance Information:"
for folder in "${folders[@]}"; do
    if [ -d "$folder" ]; then
        json_files=$(find "$folder" -type f -name "*.json" 2>/dev/null)
        if [ -n "$json_files" ]; then
            for json_file in $json_files; do
                # Retrieve the public key using solana-keygen pubkey
                public_key=$(solana-keygen pubkey "$json_file" 2>/dev/null)
                
                if [ -n "$public_key" ]; then
                    # Get the balance of the public key
                    balance=$(solana balance "$json_file" 2>/dev/null)
                    # Format output for each JSON file with key, balance, and file path
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
