#!/bin/bash

# Define color variables
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'  # No Color / Reset

# Initialize output variable for a clean final report
output=""

# Prompt user to decide if they want to check logs
echo -n "Do you want to check recent validator logs for errors? (yes/no): "
read check_logs

# Prompt user to decide if they want to perform a speed test
echo -n "Do you want to perform a network speed test? (yes/no): "
read run_speedtest

# Check Ubuntu version
ubuntu_version=$(lsb_release -d | awk -F"\t" '{print $2}')
output+="${BLUE}Ubuntu Version:${NC} $ubuntu_version\n"

# Check Solana installation and version
if command -v solana &> /dev/null; then
    solana_version=$(solana --version)
    output+="${BLUE}Solana Version:${NC} $solana_version\n"
else
    output+="${BLUE}Solana Version:${NC} Not installed\n"
fi

# Check firewall ports
output+="\n${BLUE}Firewall Port Status:${NC}\n"
required_ports=(8000:10000 3334 22)
for port in "${required_ports[@]}"; do
    if sudo ufw status | grep -q "$port"; then
        output+="Port $port is open\n"
    else
        output+="Port $port is closed\n"
    fi
done

# Check for necessary folders
output+="\n${BLUE}Folder Check:${NC}\n"
folders=("$HOME/.config/solana" "$HOME/xolana" "$HOME/x1_validator")
for folder in "${folders[@]}"; do
    if [ -d "$folder" ]; then
        output+="Folder exists: ${GREEN}$folder${NC}\n"
    else
        output+="Folder missing: ${GREEN}$folder${NC}\n"
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
output+="\n${BLUE}=== Disk Usage ===${NC}\n"
root_partition=$(df -h / | grep '/' | awk '{print $1}')
disk_total=$(df -h / | grep '/' | awk '{print $2}')
disk_used=$(df -h / | grep '/' | awk '{print $3}')
disk_free=$(df -h / | grep '/' | awk '{print $4}')
output+="Partition: $root_partition\n"
output+="Total: $disk_total\n"
output+="Used: $disk_used\n"
output+="Free: $disk_free\n"

# System Uptime
output+="\n${BLUE}=== System Uptime ===${NC}\n"
uptime=$(uptime -p | sed 's/up //')
output+="Uptime: $uptime\n"

# Set the RPC endpoint for the network (using the correct X1 network endpoint)
network_rpc="http://xolana.xen.network:8899"  # Replace this if your endpoint changes

# Network Connectivity Check (curl to check the specified network RPC Server)
output+="\n${BLUE}=== Network Connectivity ===${NC}\n"
if curl -s --connect-timeout 5 "$network_rpc" &> /dev/null; then
    output+="Network RPC ($network_rpc) is reachable.\n"
else
    output+="Network RPC ($network_rpc) is not reachable.\n"
fi

# Validator Logs Check (Last 5 "ERROR" Entries) - Only if user chose 'yes'
if [[ "$check_logs" =~ ^[Yy][Ee][Ss]$ ]]; then
    output+="\n${BLUE}=== Recent Validator Errors ===${NC}\n"
    log_file="/var/log/solana/validator.log"
    if [ ! -f "$log_file" ]; then
        log_file=$(find / -type f -name "validator.log" 2>/dev/null | head -n 1)
    fi

    if [ -f "$log_file" ]; then
        recent_errors=$(grep "ERROR" "$log_file" | tail -n 5)
        if [ -n "$recent_errors" ]; then
            output+="Log File: ${GREEN}$log_file${NC}\nRecent Errors:\n$recent_errors\n"
        else
            output+="No recent errors found in the validator logs.\n"
        fi
    else
        output+="Validator log file not found.\n"
    fi
else
    output+="\nValidator log check skipped by user.\n"
fi

# Find JSON files in specified directories and retrieve their public keys and balances
output+="\n${BLUE}JSON Files Public Key and Balance Information:${NC}\n"
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
                    output+="File: ${GREEN}$json_file${NC} | Public Key: ${RED}$public_key${NC} | Balance: ${RED}$balance${NC}\n"
                else
                    output+="File: ${GREEN}$json_file${NC} | Unable to retrieve public key\n"
                fi
            done
        else
            output+="No JSON files found in ${GREEN}$folder${NC}\n"
        fi
    fi
done

# Output main report
echo -e "$output"

# Network Speed Test Section
if [[ "$run_speedtest" =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "\n${BLUE}=== Network Speed Test ===${NC}"
    if command -v speedtest-cli &> /dev/null; then
        # Run speed test and simplify output
        echo -n "Testing download speed................................................................................"
        download_speed=$(speedtest-cli --no-upload | grep 'Download:' | awk '{print $2, $3}')
        echo -e "\nDownload: ${download_speed}"

        echo -n "Testing upload speed......................................................................................................"
        upload_speed=$(speedtest-cli --no-download | grep 'Upload:' | awk '{print $2, $3}')
        echo -e "\nUpload: ${upload_speed}"
    else
        # Prompt to install speedtest-cli
        echo -e "${RED}speedtest-cli is not installed.${NC}"
        echo -e "${BLUE}To install it, run:${NC} sudo apt install speedtest-cli"
    fi
else
    echo -e "${YELLOW}Speed test skipped by user.${NC}"
fi
