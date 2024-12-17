#!/bin/bash

# Set the RPC endpoint for the network (using the correct X1 network endpoint)
network_rpc="http://xolana.xen.network:8899"  # Replace this if your endpoint changes

# Define the folders to check for JSON files (only root of agave-xolana and .config/solana)
folders=("$HOME/.config/solana" "$HOME/agave-xolana")

# Function to display the options
function display_menu() {
    echo -e "\nChoose an option:"
    echo -e "1) Perform a full test"
    echo -e "2) Balance check only"
    echo -e "3) Speed test only"
    echo -e "4) Check logs for errors"
    echo -e "5) Network connectivity check"
    echo -e "6) System stats monitor"
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
        speedtest-cli
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

# Function to monitor system stats
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
        sleep "$REFRESH_RATE"
        rx_new=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
        tx_new=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)
        rx_kbs=$(echo "scale=2; ($rx_new - $rx) / 1024 / $REFRESH_RATE" | bc)
        tx_kbs=$(echo "scale=2; ($tx_new - $tx) / 1024 / $REFRESH_RATE" | bc)
        printf "Rx: %-8s kb/s | Tx: %-8s kb/s\n" "$rx_kbs" "$tx_kbs"

        # Memory stats
        mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        mem_free=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        mem_used=$((mem_total - mem_free))
        mem_percentage=$((100 * mem_used / mem_total))
        printf "Mem: %0.2fG / %0.2fG (%d%%)\n" "$((mem_used / 1024 / 1024))" "$((mem_total / 1024 / 1024))" "$mem_percentage"

        # CPU Stats
        echo -e "\nX1 CPU Usage:"
        for ((c = 0; c < num_cpus; c++)); do
            usage=$(awk -v cpu="cpu$c" '$1 == cpu {print 100 - $5}' /proc/stat)
            printf "CPU%-2d: %-3s%% " "$c" "$usage"
            [[ $((c % 4)) -eq 3 ]] && echo ""  # New line every 4 CPUs
        done
        echo -e "\n\nPress Ctrl+C to return to the main menu."
        sleep "$REFRESH_RATE"
    done
}

# Main loop
while true; do
    display_menu
    read -r user_choice
    case "$user_choice" in
        1)  # Full test
            echo -e "\nPerforming full test..."
            balance_check
            speed_test
            log_check
            network_check
            ;;
        2)  balance_check ;;
        3)  speed_test ;;
        4)  log_check ;;
        5)  network_check ;;
        6)  system_stats ;;
        q)  echo -e "\nExiting. Goodbye!"; break ;;
        *)  echo -e "\nInvalid option. Please try again." ;;
    esac
done
