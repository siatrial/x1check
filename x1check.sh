#!/bin/bash

# Set the RPC endpoint for the network (using the correct X1 network endpoint)
network_rpc="http://xolana.xen.network:8899"  # Replace this if your endpoint changes

# Define the folders to check for JSON files (only root of agave-xolana and .config/solana)
folders=("$HOME/.config/solana" "$HOME/agave-xolana")

# Refresh rate for stats option
REFRESH_RATE=0.25

# Function to display the options
function display_menu() {
    echo -e "\nChoose an option:"
    echo -e "1. Perform full test"
    echo -e "2. Balance check only"
    echo -e "3. Speed test only"
    echo -e "4. Log check for errors only"
    echo -e "5. Network check only"
    echo -e "6. System stats monitor"
    echo -e "q. Quit"
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
        echo -e "$(speedtest-cli --simple)"
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

# Function to display system stats monitor
function system_stats() {
    tput civis  # Hide cursor
    trap 'tput cnorm; exit 0' SIGINT SIGTERM
    clear
    num_cpus=$(nproc)

    get_cpu_usage() {
        awk '/^cpu[0-9]/ {
            total = $2 + $3 + $4 + $5 + $6 + $7 + $8;
            idle = $5;
            print $1, total, idle
        }' /proc/stat
    }

    declare -A prev_total prev_idle
    while read -r cpu total idle; do
        prev_total[$cpu]=$total
        prev_idle[$cpu]=$idle
    done < <(get_cpu_usage)

    while true; do
        clear
        echo "X1 System Stats Monitor"
        echo "-----------------------------------------"

        rx_kbs=$(awk '{print $1}' /sys/class/net/*/statistics/rx_bytes)
        tx_kbs=$(awk '{print $1}' /sys/class/net/*/statistics/tx_bytes)

        printf "Rx: %s kb/s | Tx: %s kb/s\n" "$rx_kbs" "$tx_kbs"
        
        # CPU bars
        echo "X1 CPU Usage:"
        for ((row = 5; row >= 0; row--)); do
            for ((c = 0; c < num_cpus; c++)); do
                usage=${core_usage[cpu$c]:-0}
                height=$((usage / 20))
                if ((height >= row)); then
                    printf "\e[32m█\e[0m "
                else
                    printf "  "
                fi
            done
            echo ""
        done
        sleep $REFRESH_RATE
    done
}

# Main loop
while true; do
    display_menu
    read -r user_choice

    case "$user_choice" in
        1)  # Full test
            echo -e "\nPerforming full test..."
            network_check
            log_check
            balance_check
            ;;
        2) balance_check ;;
        3) speed_test ;;
        4) log_check ;;
        5) network_check ;;
        6) system_stats ;;
        q) echo -e "\nExiting the script. Goodbye!"; break ;;
        *) echo -e "\nInvalid option. Please try again." ;;
    esac
done
