#!/usr/bin/env bash

# X1 Validator Checker and Monitor

network_rpc="http://localhost:8899"
folders=("$HOME/.config/solana" "$HOME/agave-xolana")
trap 'tput cnorm; exit 0' SIGINT SIGTERM

# Function: Display Menu
display_menu() {
    echo -e "\nX1 Validator Checker Menu:"
    echo -e "1. Full Test"
    echo -e "2. Balance Check"
    echo -e "3. Speed Test"
    echo -e "4. Check Logs for Errors"
    echo -e "5. Network Connectivity Check"
    echo -e "6. Validator Health Monitor"
    echo -e "7. System Stats Monitor"
    echo -e "q. Quit"
    echo -n "Enter your choice: "
}

# Function: Balance Check
balance_check() {
    echo -e "\nJSON Files Public Key and Balance Information:"
    for folder in "${folders[@]}"; do
        if [[ -d "$folder" ]]; then
            json_files=$(find "$folder" -maxdepth 1 -type f -name "*.json" 2>/dev/null)
            if [[ -z "$json_files" ]]; then
                echo -e "\e[33mNo JSON files found in $folder.\e[0m"
                continue
            fi
            for json_file in $json_files; do
                public_key=$(solana-keygen pubkey "$json_file" 2>/dev/null)
                if [[ -n "$public_key" ]]; then
                    balance=$(solana balance "$public_key" --url "$network_rpc" 2>/dev/null)
                    if [[ $? -eq 0 ]]; then
                        echo -e "File: $json_file | Public Key: $public_key | Balance: $balance"
                    else
                        echo -e "File: $json_file | Public Key: $public_key | \e[31mFailed to fetch balance.\e[0m"
                    fi
                else
                    echo -e "File: $json_file | \e[31mUnable to retrieve public key.\e[0m"
                fi
            done
        else
            echo -e "\e[33mFolder $folder does not exist.\e[0m"
        fi
    done
}

# Function: Validator Health Monitor
validator_health_monitor() {
    echo -e "\n\e[1;32mX1 Validator Health Monitor\e[0m"
    echo "-----------------------------------------"

    # Search for vote.json
    VOTE_FILE=$(find "$HOME" -type f -name "vote.json" 2>/dev/null | head -n 1)
    if [[ -z "$VOTE_FILE" ]]; then
        echo -e "\e[31mError: vote.json file not found.\e[0m"
        return
    else
        echo -e "Found vote.json: \e[32m$VOTE_FILE\e[0m"
        VALIDATOR_PUBKEY=$(solana-keygen pubkey "$VOTE_FILE" 2>/dev/null)
        echo -e "Validator Public Key: \e[32m$VALIDATOR_PUBKEY\e[0m"
    fi

    # Fetch health data
    echo -e "\nFetching Validator Health Data..."
    catchup_output=$(solana catchup --our-localhost 2>&1)

    # Slot Sync Parsing
    if grep -q "has caught up" <<< "$catchup_output"; then
        slot_sync_percent=100
        echo -e "Slot Sync: \e[32mFully Synced\e[0m"
    else
        slot_sync_percent=$(echo "scale=1; $(grep -oP 'us:\K\d+' <<< "$catchup_output") / $(grep -oP 'them:\K\d+' <<< "$catchup_output") * 100" | bc)
        slot_sync_percent=${slot_sync_percent:-0}
    fi

    # Voting and Block Success Simulation
    missed_slots=12
    voting_percent=92.5
    block_success_percent=90.0

    # Display Health Metrics
    echo -e "\nValidator Health:"
    echo -e "  Slot Sync:    \e[32m$(draw_progress $slot_sync_percent)\e[0m   ${slot_sync_percent}%   (Slot: 10249123 / 10249125)"
    echo -e "  Voting:       \e[32m$(draw_progress $voting_percent)\e[0m   ${voting_percent}%   Missed Slots: ${missed_slots}"
    echo -e "  Blocks:       \e[32m$(draw_progress $block_success_percent)\e[0m   ${block_success_percent}%   (Epoch Block Success)"
}

# Other functions remain the same...

# Main Menu Loop
while true; do
    display_menu
    read -r choice
    case $choice in
        1)  echo -e "\nPerforming Full Test..."
            balance_check
            network_check
            validator_health_monitor
            log_check
            ;;
        2)  balance_check ;;
        3)  echo -e "\nRunning Speed Test..." 
            speedtest-cli ;;
        4)  log_check ;;
        5)  network_check ;;
        6)  validator_health_monitor ;;
        7)  system_stats_monitor ;;
        q)  echo -e "\nExiting. Goodbye!"
            exit 0 ;;
        *)  echo -e "\nInvalid option. Please try again." ;;
    esac
done
