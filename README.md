X1 Validator Checker

A bash script to check the setup status of a Solana validator/staker on an Ubuntu server. 
This script provides comprehensive system and validator status information, 
including Solana version, firewall settings, disk usage, uptime, 
validator status, staking status, and public key balance details for configured JSON keypair files.

Features

- Checks Ubuntu version and Solana installation/version
- Verifies if required firewall ports are open (if shown as closed could mean you have a seperate hardware firewall or service provider firewall )
- Inspects specific folders for configuration files (`.config/solana`, `xolana`, `x1_validator`)
- Retrieves public keys and Solana balances for each keypair JSON file
- Shows disk usage for the root partition
- Displays system uptime
- Checks logs for errors ( decide yes or no at start )
- Checks if the validator is running and staking status is active

## Prerequisites

Ensure the following are installed on your Ubuntu system:

This script uses Solana CLI commands (`solana balance`, `solana-keygen`) to interact with Solana accounts.
- **jq**: Used for parsing JSON files in the script.

To install `jq` and Solana CLI, use:
```bash
sudo apt update
sudo apt install jq
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"

nano x1check.sh
paste in script
then save

chmod +x x1check.sh

./x1check.sh
