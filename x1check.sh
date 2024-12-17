#!/bin/bash

# Set the RPC endpoint for the network (using the correct X1 network endpoint)
network_rpc="http://xolana.xen.network:8899"
folders=("$HOME/.config/solana" "$HOME/agave-xolana")
REFRESH_RATE=0.25
IFACE=$(ip link | awk -F: '$0 ~ "^[0-9]+:" {print $2; exit}' | tr -d ' ')

# Function to display the main menu
function display_menu() {
    echo -e "\nChoose an option:"
    echo -e "1. Perform full test"
    echo -e "2. Balance check"
    echo -e "3. Speed test"
    echo -e "4. Log check"
    echo -e "5. Network check"
    echo -e "6. System stats monitor"
    echo -e "q. Quit"
    echo -n "Your choice: "
}

# Function to check balances
function balance_check() {
    echo -e "\nJSON Files Public Key and Balance Information:"
    for folder in "${folders[@]}"; do
        if [ -d "$folder" ]; then
            json_files=$(find "$folder" -maxdepth 1 -type f -name "*.json" 2>/dev/null)
            for json_file in $json_files; do
                public_key=$(solana-keygen pubkey "$json_file" 2>/dev/null)
                balance=$(solana balance "$public_key" --url "$network_rpc" 2>/dev/null)
                echo -e "File: $json_file | Public Key: $public_key | Balance: $balance"
            done
        fi
    done
}

# Function for speed test
function speed_test() {
    echo -e "\n=== Network Speed Test ==="
    if command -v speedtest-cli &>/dev/null; then
        speedtest-cli --simple
    else
        echo "speedtest-cli not installed. Install with: sudo apt install speedtest-cli"
    fi
}

# Function for log check
function log_check() {
    echo -e "\n=== Validator Log Errors ==="
    log_file="$HOME/agave-xolana/validator.log"
    if [ -f "$log_file" ]; then
        grep "ERROR" "$log_file" | tail -n 5
    else
        echo "Validator log file not found."
    fi
}

# Function for network check
function network_check() {
    echo -e "\n=== Network Connectivity ==="
    if curl -s --connect-timeout 5 "$network_rpc" &>/dev/null; then
        echo "Network RPC ($network_rpc) is reachable."
    else
        echo "Network RPC ($network_rpc) is not reachable."
    fi
}

# System stats monitor
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

    get_memory_usage() {
        mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        mem_free=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        mem_used=$((mem_total - mem_free))
        mem_percentage=$((100 * mem_used / mem_total))
        echo "$mem_used $mem_total $mem_percentage"
    }

    get_swap_usage() {
        swap_total=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
        swap_free=$(awk '/SwapFree/ {print $2}' /proc/meminfo)
        swap_used=$((swap_total - swap_free))
        swap_percentage=$((100 * swap_used / swap_total))
        echo "$swap_used $swap_total $swap_percentage"
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

        # RX/TX Monitoring
        rx_old=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
        tx_old=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)
        sleep $REFRESH_RATE
        rx_new=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
        tx_new=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)
        rx_kbs=$(echo "scale=2; ($rx_new - $rx_old) / 1024 / $REFRESH_RATE" | bc)
        tx_kbs=$(echo "scale=2; ($tx_new - $tx_old) / 1024 / $REFRESH_RATE" | bc)
        printf "Rx: %-8s kb/s | Tx: %-8s kb/s\n" "$rx_kbs" "$tx_kbs"

        # Memory bars
        read mem_used mem_total mem_percentage < <(get_memory_usage)
        read swap_used swap_total swap_percentage < <(get_swap_usage)
        printf "Mem["
        for ((i = 0; i < 50; i++)); do
            ((i < mem_percentage / 2)) && printf "\e[33m|\e[0m" || printf " "
        done
        printf "] %0.2fG/%0.2fG\n" "$((mem_used / 1024 / 1024))" "$((mem_total / 1024 / 1024))"

        printf "Swp["
        for ((i = 0; i < 50; i++)); do
            ((i < swap_percentage / 2)) && printf "\e[35m|\e[0m" || printf " "
        done
        printf "] %0.2fM/%0.2fM\n" "$((swap_used / 1024))" "$((swap_total / 1024))"

        # CPU Usage
        echo -e "\nX1 CPU Cores:"
        for ((row = 5; row >= 0; row--)); do
            for ((c = 0; c < num_cpus; c++)); do
                usage=$((RANDOM % 100)) # Placeholder for real usage calculation
                height=$((usage / 20))
                if ((height >= row)); then
                    printf "\e[32m█\e[0m"
                else
                    printf " "
                fi
            done
            echo ""
        done
    done
}

# Main loop
while true; do
    display_menu
    read -r choice
    case "$choice" in
        1) echo "Performing full test..."; balance_check; speed_test; log_check; network_check ;;
        2) balance_check ;;
        3) speed_test ;;
        4) log_check ;;
        5) network_check ;;
        6) system_stats ;;
        q) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option, try again." ;;
    esac
done
