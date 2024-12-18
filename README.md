X1 Validator Checker Installation

Installation
To install and set up x1check, run the following command in your terminal:

curl -s https://raw.githubusercontent.com/siatrial/x1check/main/install.sh | bash

How to Run
After installation, you can run the following commands:

Run the validator checker:
x1check

Run the system stats monitor:
x1stats


About X1 Validator Checker

X1 Validator Checker is a powerful bash script designed to provide detailed insights into the setup and health of a Solana validator or staker on an Ubuntu server. The script offers real-time monitoring and in-depth checks to ensure your validator operates smoothly.

Features
Interactive Menu
The script features an interactive menu to choose between a full test or specific checks:

1: Full Test
2: Balance Check
3: Speed Test
4: Check Logs for Errors (last 100 lines)
5: Network Connectivity Check
6: Validator Health Monitor
7: System Stats Monitor
q: Quit the script
Detailed Tests and Checks
1. Full Test

The full test performs the following:

System Information:
Checks Ubuntu version.
Verifies Solana CLI version and installation.
Firewall Ports:
Ensures required ports (8000:10000, 3334, 22) are open (note: may not detect external firewalls).
Configuration Folders:
Searches for validator-specific folders like agave-xolana, .config/solana, xolana, and x1_validator.
Balance Check:
Retrieves public keys and Solana balances for keypair JSON files.
Disk Usage:
Displays statistics for the root partition.
System Uptime:
Reports the system uptime.
Network Connectivity:
Verifies RPC endpoint connectivity.
Log Errors:
Checks the last 100 lines of the validator logs for errors.
Validator Status:
Confirms if the validator process is running and validates staking status.
Network Speed Test:
Tests internet upload/download speed using speedtest-cli.
2. Balance Check

Scans for JSON keypair files in the specified folders.
Retrieves and displays the public keys and their associated Solana balances.
3. Speed Test

Runs a network speed test using speedtest-cli.
Displays upload and download speeds.
4. Check Logs for Errors

Analyzes the last 100 lines of the validator logs.
Reports any errors found, or confirms the absence of errors.
5. Network Connectivity Check

Tests the connectivity of the Solana RPC endpoint.
6. Validator Health Monitor

Automatically detects the vote.json file to identify the validator public key.
Performs health checks using solana catchup:
Slot Sync:
Reports the percentage of slot sync completion.
Voting:
Displays voting success percentage and missed slots.
Block Success:
Reports the percentage of successful block completions.
Progress bars are used for visual representation of these metrics.
7. System Stats Monitor

Provides real-time monitoring of system metrics:
Network RX/TX: Reports network throughput in kb/s.
Memory Usage: Displays a graphical bar showing memory usage.
CPU Core Utilization: Graphical bars show per-core CPU utilization.
Prerequisites

Ensure the following tools are installed on your Ubuntu system:

Solana CLI
Required for interacting with Solana accounts and validator processes.
jq
Used for parsing JSON files in the script.
Install it with:
sudo apt install jq
speedtest-cli
Used for internet speed testing.
Install it with:
sudo apt install speedtest-cli
