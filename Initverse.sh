#!/bin/bash

# Colors
BLUE='\033[0;34m'         # Normal blue
LIGHTBLUE='\033[1;34m'    # Light blue
CYAN='\033[0;36m'         # Cyan
LIGHTCYAN='\033[1;36m'    # Light cyan
NC='\033[0m'

# Configuration
WALLET_ADDRESS=""
WORKER_NAME="default_worker"
MINING_SOFTWARE_URL="https://github.com/Project-InitVerse/ini-miner/releases/download/v1.0.0/iniminer-linux-x64"
CPU_CORES=$(nproc)
RESTART_INTERVAL=3600  # 1 hour in seconds

# Available pools
declare -A MINING_POOLS=(
    ["YatesPool"]="pool-a.yatespool.com:31588"
    ["BackupPool"]="pool-b.yatespool.com:32488"
)

# Function to display banner
show_banner() {
    clear
    echo -e "${LIGHTBLUE}╔════════════════════════════════╗${NC}"
    echo -e "${LIGHTBLUE}║  InitVerse Mainnet x Brrrskuy  ║${NC}"
    echo -e "${LIGHTBLUE}╚════════════════════════════════╝${NC}"
    echo
}

# Function to validate wallet address
validate_wallet() {
    if [[ ! $1 =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        echo -e "${BLUE}Invalid wallet address!${NC}"
        return 1
    fi
    return 0
}

# Function to run mining with auto-restart
run_mining() {
    local mining_cmd="$1"
    while true; do
        echo -e "${BLUE}Starting mining process...${NC}"
        echo -e "${CYAN}Mining command: $mining_cmd${NC}"
        
        # Calculate and show next restart time
        local next_restart=$(date -d "+1 hour" +"%H:%M:%S")
        echo -e "${LIGHTCYAN}Next auto-restart scheduled at: $next_restart${NC}"
        
        # Run the mining command
        eval "$mining_cmd"
        
        echo -e "${LIGHTCYAN}Mining process ended. Restarting in 10 seconds...${NC}"
        sleep 10
        
        # Kill any remaining mining processes
        pkill -f iniminer-linux-x64
    done
}

# Function to setup mining
setup_mining() {
    # Get wallet address
    while [ -z "$WALLET_ADDRESS" ] || ! validate_wallet "$WALLET_ADDRESS"; do
        echo -e "${LIGHTCYAN}Enter your wallet address (0x...):${NC}"
        read WALLET_ADDRESS
    done

    # Get worker name
    echo -e "${LIGHTCYAN}Enter worker name (default: $WORKER_NAME):${NC}"
    read input_worker
    WORKER_NAME=${input_worker:-$WORKER_NAME}

    # Select mining pool
    echo -e "${LIGHTCYAN}Available Mining Pools:${NC}"
    local i=1
    for pool_name in "${!MINING_POOLS[@]}"; do
        echo -e "$i) $pool_name (${MINING_POOLS[$pool_name]})"
        ((i++))
    done

    local pool_choice
    read -p "Select pool (1-${#MINING_POOLS[@]}): " pool_choice
    local pool_address=$(echo "${MINING_POOLS[@]}" | cut -d' ' -f$pool_choice)

    # Setup CPU cores
    echo -e "${LIGHTCYAN}Available CPU cores: $CPU_CORES${NC}"
    read -p "How many cores to use? (1-$CPU_CORES): " cores_to_use
    cores_to_use=${cores_to_use:-1}

    # Setup restart interval
    echo -e "${LIGHTCYAN}Current auto-restart interval: ${RESTART_INTERVAL} seconds (1 hour)${NC}"
    read -p "Enter new restart interval in seconds (press Enter to keep current): " new_interval
    if [[ -n "$new_interval" ]] && [[ "$new_interval" =~ ^[0-9]+$ ]]; then
        RESTART_INTERVAL=$new_interval
    fi

    # Create directory and setup
    mkdir -p ini-miner && cd ini-miner
    echo -e "${LIGHTCYAN}Downloading mining software...${NC}"
    wget "$MINING_SOFTWARE_URL" -O iniminer-linux-x64
    chmod +x iniminer-linux-x64

    # Prepare mining command
    local mining_cmd="./iniminer-linux-x64 --pool stratum+tcp://${WALLET_ADDRESS}.${WORKER_NAME}@${pool_address}"
    for ((i=0; i<cores_to_use; i++)); do
        mining_cmd+=" --cpu-devices $i"
    done

    # Start mining with auto-restart
    echo -e "${LIGHTCYAN}Starting mining with auto-restart every ${RESTART_INTERVAL} seconds${NC}"
    echo -e "${LIGHTCYAN}Press Ctrl+C twice to stop mining completely${NC}"
    run_mining "$mining_cmd"
}

# Function to check system
check_system() {
    echo -e "${LIGHTBLUE}System Information:${NC}"
    echo -e "CPU Cores: ${CYAN}$CPU_CORES${NC}"
    echo -e "Memory: ${CYAN}$(free -h | awk '/^Mem:/{print $2}')${NC}"
    echo -e "Disk Space: ${CYAN}$(df -h / | awk 'NR==2 {print $4}')${NC}"
    echo -e "Auto-restart Interval: ${CYAN}${RESTART_INTERVAL} seconds${NC}"
    read -p "Press Enter to continue..."
}

# Main menu
while true; do
    show_banner
    echo -e "${LIGHTBLUE}1) Start Mining${NC}"
    echo -e "${LIGHTBLUE}2) Check System${NC}"
    echo -e "${LIGHTBLUE}3) Exit${NC}"
    echo
    read -p "Select option (1-3): " choice

    case $choice in
        1) setup_mining ;;
        2) check_system ;;
        3) echo -e "${BLUE}Dahhh Close?? Follow Github: @Brrrskuy ${NC}"; exit 0 ;;
        *) echo -e "${CYAN}Invalid option${NC}"; sleep 1 ;;
    esac
done
