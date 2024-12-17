#!/bin/bash

# Set the RPC endpoint for the network (using the correct X1 network endpoint)
network_rpc="http://xolana.xen.network:8899"

# Define the folders to check for JSON files
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

# Function to monitor system stats
function system_stats() {
    REFRESH_RATE=0.25  # Floating-point refresh rate
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

    # Initialize previous CPU stats
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
        sleep "$REFRESH_RATE"
        rx_new=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
        tx_new=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)
        rx_kbs=$(awk "BEGIN {printf \"%.2f\", ($rx_new - $rx_old) / 1024 / $REFRESH_RATE}")
        tx_kbs=$(awk "BEGIN {printf \"%.2f\", ($tx_new - $tx_old) / 1024 / $REFRESH_RATE}")
        printf "Rx: %-8s kb/s | Tx: %-8s kb/s\n" "$rx_kbs" "$tx_kbs"

        # Memory stats
        mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        mem_free=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        mem_used=$((mem_total - mem_free))
        mem_percentage=$((100 * mem_used / mem_total))
        printf "Mem: %0.2fG / %0.2fG (%d%%)\n" "$((mem_used / 1024 / 1024))" "$((mem_total / 1024 / 1024))" "$mem_percentage"

        # CPU Stats
        echo -e "\nX1 CPU Usage:"
        while read -r cpu total idle; do
            delta_total=$((total - prev_total[$cpu]))
            delta_idle=$((idle - prev_idle[$cpu]))
            usage=$((100 * (delta_total - delta_idle) / delta_total))
            prev_total[$cpu]=$total
            prev_idle[$cpu]=$idle
            printf "%-5s %3d%% " "$cpu" "$usage"
        done < <(get_cpu_usage)
        echo -e "\n\nPress Ctrl+C to return to the main menu."
        sleep "$REFRESH_RATE"
    done
}

# Main loop
while true; do
    display_menu
    read -r user_choice
    case "$user_choice" in
        1) echo -e "\nPerforming full test...";;
        2) echo -e "\nPerforming balance check...";;
        3) echo -e "\nPerforming speed test...";;
        4) echo -e "\nChecking logs for errors...";;
        5) echo -e "\nChecking network connectivity...";;
        6) system_stats;;
        q) echo -e "\nExiting. Goodbye!"; break;;
        *) echo -e "\nInvalid option. Please try again.";;
    esac
done
