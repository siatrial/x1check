X1 Validator Checker Installation

To install and set up x1check, run this command in your terminal:

curl -s https://raw.githubusercontent.com/siatrial/x1check/main/install.sh | bash
Then run the script with:

x1check
About X1 Validator Checker

X1 Validator Checker is a bash script designed to check the setup status of a Solana validator or staker on an Ubuntu server.
This script provides comprehensive system and validator status information, including:

Solana version and installation check
Firewall settings verification
Disk usage monitoring
System uptime and performance stats
Validator and staking status validation
Public key balance details for configured JSON keypair files
Network speed test and error log analysis
Features

Interactive Menu
Easily choose between a full test or specific checks:

1 - Full Test
2 - Balance Check
3 - Speed Test
4 - Check Logs for Errors
5 - Network Connectivity Check
6 - System Stats Monitor
q - Quit the script
Full Test
The full test performs the following checks:

System Information
Ubuntu version
Solana CLI version
Firewall Ports
Verifies required ports (8000:10000, 3334, 22)
Configuration Folders
Scans for agave-xolana, .config/solana, xolana, and x1_validator folders.
Balance Check
Retrieves public keys and Solana balances for keypair JSON files.
Disk Usage
Displays usage statistics for the root partition.
System Uptime
Shows current system uptime.
Network Connectivity
Checks RPC endpoint connectivity.
Log Errors
Optionally searches validator logs for errors.
Validator Status
Checks if the validator process is running and validates staking status.
Network Speed Test
Uses speedtest-cli for internet upload/download speed testing.
System Stats Monitor
Monitor real-time system stats including:

Network RX/TX (kb/s)
Memory Usage (graphical bars)
CPU Core Utilization (graphical bars, per-core display)
Run the stats monitor with:

./x1stats
Prerequisites

Ensure the following tools are installed on your Ubuntu system:

Solana CLI
Required for interacting with Solana accounts and validator processes.
jq
Used for parsing JSON files in the script.
speedtest-cli
For internet upload/download speed testing.
Install prerequisites using the following commands:

sudo apt update
sudo apt install jq speedtest-cli
To install Solana CLI, follow the official guide:
Solana CLI Installation

How to Run

After installation:

Launch the x1check script:
x1check
To monitor system stats, run:
./x1stats
Contributions

Contributions are welcome! Please open an issue or pull request on GitHub.

