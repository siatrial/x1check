#!/bin/bash

# Set the RPC endpoint for the network
network_rpc="http://xolana.xen.network:8899"

# Define the folders to check for JSON files
folders=("$HOME/.config/solana" "$HOME/agave-xolana")

# Refresh rate for stats
REFRESH_RATE=0.25

# Function to display the menu
function display_menu() {
    echo -e "\nChoose an option:"
    echo -e "1. Full test"
    echo -e "2. Balance check"
    echo -e "3. Speed test"
    echo -e "4. Check logs for errors"
    echo -e "5. Network check"
    echo -e "6. Stats (CPU, Memory, Network)"
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
        speedtest-cli
    else
        echo -e "speedtest-cli is not installed. Install it using: sudo apt install speedtest-cli"
    fi
}

# Function to perform a log check
function log_check() {
    echo -e "\n=== Recent Validator Errors ==="
    log_file="$HOME/agave-xolana/validator.log"
    if [ -f "$log_file" ]; then
        grep "ERROR" "$log_file" | tail -n 5 || echo "No errors found."
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

# Function to display stats
function stats() {
    clear
    num_cpus=$(nproc)
    tput civis  # Hide cursor

    # Function to get CPU usage
    get_cpu_usage() {
        awk '/^cpu[0-9]/ {
            total = $2 + $3 + $4 + $5 + $6 + $7 + $8;
            idle = $5;
            print $1, total, idle
        }' /proc/stat
    }

    while true; do
        rx_old=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
        tx_old=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)
        sleep $REFRESH_RATE
        rx_new=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
        tx_new=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)
        rx_kbs=$(echo "scale=2; ($rx_new - $rx_old) / 1024 / $REFRESH_RATE" | bc)
        tx_kbs=$(echo "scale=2; ($tx_new - $tx_old) / 1024 / $REFRESH_RATE" | bc)

        mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        mem_free=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        mem_used=$((mem_total - mem_free))
        mem_percentage=$((100 * mem_used / mem_total))

        tput cup 0 0
        echo "X1 System Stats:"
        echo "--------------------------"
        printf "Rx: %-8s kb/s | Tx: %-8s kb/s\n" "$rx_kbs" "$tx_kbs"
        printf "Mem: %d%% [%0.2fG/%0.2fG]\n" "$mem_percentage" "$((mem_used / 1024 / 1024))" "$((mem_total / 1024 / 1024))"

        # CPU Stats
        declare -A core_usage
        while read -r cpu total idle; do
            prev_total=${prev_total[$cpu]:-0}
            prev_idle=${prev_idle[$cpu]:-0}
            delta_total=$((total - prev_total))
            delta_idle=$((idle - prev_idle))
            usage=$(( (100 * (delta_total - delta_idle)) / delta_total ))
            core_usage[$cpu]=$usage
            prev_total[$cpu]=$total
            prev_idle[$cpu]=$idle
        done < <(get_cpu_usage)

        echo "CPU Usage:"
        for ((c = 0; c < num_cpus; c++)); do
            usage=${core_usage[cpu$c]:-0}
            height=$((usage / 20))
            printf "C%-2d: " "$c"
            for ((i = 0; i < 5; i++)); do
                if ((i < height)); then printf "█"; else printf " "; fi
            done
            printf " %d%%\n" "$usage"
        done
        sleep $REFRESH_RATE
    done
}

# Main loop
while true; do
    display_menu
    read -r user_choice
    case "$user_choice" in
        1) echo "Running full test..."; network_check; log_check; balance_check ;;
        2) echo "Running balance check..."; balance_check ;;
        3) echo "Running speed test..."; speed_test ;;
        4) echo "Checking logs for errors..."; log_check ;;
        5) echo "Checking network connectivity..."; network_check ;;
        6) echo "Launching stats..."; stats ;;
        q) echo "Goodbye!"; break ;;
        *) echo "Invalid option, try again." ;;
    esac
done
