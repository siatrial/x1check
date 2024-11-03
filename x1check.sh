#!/bin/bash

# Initialize output variable for a clean final report
output=""

output+="              \n"
output+="              \n"
# Check Ubuntu version
ubuntu_version=$(lsb_release -d | awk -F"\t" '{print $2}')
output+="Ubuntu Version: $ubuntu_version\n"

# Check Solana installation and version
if command -v solana &> /dev/null; then
    solana_version=$(solana --version)
    output+="Solana Version: $solana_version\n"
else
    output+="Solana is not installed\n"
fi

# Check firewall ports
output+="\nFirewall Port Status:\n"
required_ports=(8000:10000 3334 22)
for port in "${required_ports[@]}"; do
    if sudo ufw status | grep -q "$port"; then
        output+="Port $port is open\n"
    else
        output+="Port $port is closed\n"
    fi
done

# Check for necessary folders
output+="\nFolder Check:\n"
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

# System Uptime
output+="\n=== System Uptime ===\n"
uptime=$(uptime -p | sed 's/up //')
output+="Uptime: $uptime\n"

# Find JSON files in specified directories and retrieve their public keys and balances
output+="\nJSON Files Public Key and Balance Information:\n"
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
                    output+="File: $json_file | Public Key: $public_key | Balance: $balance\n"
                else
                    output+="File: $json_file | Unable to retrieve public key\n"
                fi
            done
        else
            output+="No JSON files found in $folder\n"
        fi
    fi
done

# Final Output
echo -e "$output"


