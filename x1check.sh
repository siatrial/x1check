#!/bin/bash

# Set the RPC endpoint for the network (using the correct X1 network endpoint)
network_rpc="http://xolana.xen.network:8899"  # Replace this if your endpoint changes

# Define the folders to check for JSON files
folders=("$HOME/.config/solana" "$HOME/agave-xolana")

# Function to display the options
function display_menu() {
    echo -e "\nChoose an option:"
    echo "1) Full test"
    echo "2) Balance check"
    echo "3) Speed test"
    echo "4) Check logs for errors"
    echo "5) Network check"
    echo "6) System stats monitor"
    echo -e "q) Quit"
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
        echo "Running speed test..."
        speedtest-cli --simple
    else
        echo "speedtest-cli is not installed. Install it using: sudo apt install speedtest-cli"
    fi
}

# Function to perform a log check
function log_check() {
    echo -e "\n=== Recent Validator Errors ==="
    log_file="$HOME/agave-xolana/validator.log"
    if [ -f "$log_file" ]; then
        grep "ERROR" "$log_file" | tail -n 5 || echo "No recent errors found."
    else
        echo "Validator log file not found."
    fi
}

# Function to perform a network check
function network_check() {
    echo -e "\n=== Network Connectivity ==="
    if curl -s --connect-timeout 5 "$network_rpc" &> /dev/null; then
        echo "Network RPC ($network_rpc) is reachable."
    else
        echo "Network RPC ($network_rpc) is not reachable."
    fi
}

# Function to display system stats
function system_stats() {
    REFRESH_RATE=0.25
    IFACE=$(ip link | awk -F: '$0 ~ "^[0-9]+:" {print $2; exit}' | tr -d ' ')
    trap 'tput cnorm; exit 0' SIGINT SIGTERM
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
        clear
        echo "X1 System Stats Monitor"
        echo "-----------------------------------------"

        # RX/TX Monitoring
        rx=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
        tx=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)
        sleep $REFRESH_RATE
        rx_new=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
        tx_new=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)
        rx_kbs=$(( (rx_new - rx) / 1024 / REFRESH_RATE ))
        tx_kbs=$(( (tx_new - tx) / 1024 / REFRESH_RATE ))
        echo "Rx: $rx_kbs kb/s | Tx: $tx_kbs kb/s"

        # Memory stats
        mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        mem_free=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        mem_used=$((mem_total - mem_free))
        mem_percentage=$((100 * mem_used / mem_total))
        echo -e "Memory: $((mem_used / 1024))MB / $((mem_total / 1024))MB ($mem_percentage%)"

        # CPU Stats
        echo -e "\nX1 CPU Usage:"
        for ((c = 0; c < num_cpus; c++)); do
            cpu_usage=$(top -bn1 | grep "Cpu$c" | awk '{print $2}')
            printf "CPU%-2d: %-3s%% " "$c" "$cpu_usage"
            [[ $((c % 4)) -eq 3 ]] && echo ""  # New line every 4 CPUs
        done
        echo -e "\n\nPress Ctrl+C to return to the main menu."
        sleep $REFRESH_RATE
    done
}

# Main loop
while true; do
    display_menu
    read -r user_choice

    case "$user_choice" in
        1)  # Full test
            echo "Performing full test..."
            balance_check
            speed_test
            log_check
            network_check
            ;;
        2)  # Balance check
            balance_check
            ;;
        3)  # Speed test
            speed_test
            ;;
        4)  # Log check
            log_check
            ;;
        5)  # Network check
            network_check
            ;;
        6)  # System stats monitor
            system_stats
            ;;
        q)  # Quit
            echo "Exiting. Goodbye!"
            exit 0
            ;;
        *)  # Invalid input
            echo "Invalid option. Please try again."
            ;;
    esac
done
