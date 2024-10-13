#!/bin/bash
# ANSI color code for yellow text
YELLOW='\033[1;33m'
# ANSI color code for green text
GREEN='\033[0;32m'
# ANSI color code to reset text color
NC='\033[0m'

# Function to display section headers
display_header() {
    echo -e "${YELLOW}$1${NC}"
}

progress_bar() {
    local total_steps=25
    local percent=$1

    # Remove the dot if it's present, else multiply by 10
    if [[ $percent == *.* ]]; then
        percent=$(echo "$percent" | tr -d .)
    else
        percent=$(( percent * 10 ))
    fi

    local filled_slots=$(( percent * total_steps / 1000 ))
    local empty_slots=$(( total_steps - filled_slots ))

    printf "\e[42m" # Set background color to green
    for ((i = 0; i < filled_slots; i++)); do
        printf " "
    done
    printf "\e[0m" # Reset color
    printf "\e[100m" # Set background color to grey
    for ((i = 0; i < empty_slots; i++)); do
        printf " "
    done
    printf "\e[0m" # Reset color
    printf " %.1f%%\r" "$(echo "$1" | awk '{printf "%.1f", $1}')"
}


# Check if iftop is installed
if ! command -v iftop &> /dev/null; then
    echo -e "${GREEN}iftop is not installed. Installing...${NC}"
    # Install iftop using package manager
    # You may need to adjust the package manager based on your system (apt, yum, etc.)
    sudo apt-get update
    sudo apt-get install -y iftop
else
    echo -e "${YELLOW}iftop is already installed.${NC}"
fi

# Check if speedtest is installed
if ! command -v speedtest &> /dev/null; then
    if ! command -v curl &> /dev/null; then
         echo -e "${GREEN}curl is not installed. Installing...${NC}"
        sudo apt-get install curl
    fi
    echo -e "${GREEN}Speedtest is not installed. Installing...${NC}"
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
    sudo apt-get install -y speedtest
else
    echo -e "${YELLOW}speedtest is already installed.${NC}"
fi

echo
echo -e "\e[32m   ________  ____   ______  _____    ____            ____\n  / ____/  |/  / | / / __ \/ ___/   / __ \___  _____/ __/\n / /   / /|_/ /  |/ / / / /\__ \   / /_/ / _ \/ ___/ /_  \n/ /___/ /  / / /|  / /_/ /___/ /  / ____/  __/ /  / __/  \n\____/_/  /_/_/ |_/_____//____/  /_/    \___/_/  /_/     \n\e[0m"
echo -e "\e[32mcreated by Martin Skalicky ## @maskalix\e[0m"
echo

display_header "System info"
display_system_info() {
    echo "$(lsb_release -d | cut -f2)"
    echo "$(lscpu | grep "Model name" | awk -F':' '{print $2}' | sed 's/^[ \t]*//')"
}
display_system_info
echo
# Display uptime
display_header "Uptime"
display_uptime() {
    local uptime_info=$(uptime -s)
    local start_time=$(date -d "$uptime_info" "+%F %T")
    local uptime=$(uptime -p)
    
    echo "⬆️  $uptime"
    echo "🕐 $start_time"
}
display_uptime
echo

# Display network usage
display_header "Network"
# Function to display network information
display_network_info() {
    local interface=$(ip route get 8.8.8.8 | awk 'NR==1{print $5}')
    local ip_address=$(ip addr show $interface | awk '/inet / {print $2}' | cut -d/ -f1)
    local mac_address=$(ip link show $interface | awk '/ether/ {print $2}')
    
    # Top border
    echo "╔═════════════════╦═════════════════╦═══════════════════╗"
    # Header line
    echo "║ Interface       ║ IP address      ║ MAC address       ║"
    # Middle border
    echo "╠═════════════════╬═════════════════╬═══════════════════╣"
    # Data line
    printf "║ %-15s ║ %-15s ║ %-17s ║\n" "$interface" "$ip_address" "$mac_address"
    # Bottom border
    echo "╚═════════════════╩═════════════════╩═══════════════════╝"
}
display_network_info
echo

# Display processor usage
display_header "Processor"
display_processor_usage() {
    local processor_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    progress_bar "$processor_usage"
}
display_processor_usage
echo
echo

# Display disk usage
display_header "Disk"
display_disk_usage() {
    local disk_info=$(df -h / | awk 'NR==2{printf "%.1f %.1f %.1f", $3, $2, $5}')
    read disk_used disk_all disk_percent <<< "$disk_info"
    progress_bar "$disk_percent"
    echo
    printf "%.1f GB/%.1f GB" "$disk_used" "$disk_all"
}
display_disk_usage
echo
echo

# Display RAM usage
display_header "RAM"
ram_info=$(free -m | awk 'NR==2{printf "%.1f %.1f %.1f", $3/1024, $2/1024, $3/$2*100}')
read RAM_used RAM_all RAM_percent <<< "$ram_info"

progress_bar "$RAM_percent"
echo
echo "$RAM_used GB/$RAM_all GB"
echo

# Run Ookla speedtest and display result
display_header "Speedtest"
display_speed_test() {
    local speedtest_result=$(speedtest)
    local download_speed=$(echo "$speedtest_result" | grep -oE 'Download:\s+[0-9]+\.[0-9]+ Mbps' | awk '{print $2}')
    local upload_speed=$(echo "$speedtest_result" | grep -oE 'Upload:\s+[0-9]+\.[0-9]+ Mbps' | awk '{print $2}')
    local ping=$(echo "$speedtest_result" | grep -oE 'Idle Latency:\s+[0-9]+\.[0-9]+ ms' | awk '{print $3}')
    local result_url=$(echo "$speedtest_result" | grep "Result URL" | awk '{print $3}')
    
    echo "╔═════════════════╦═════════════════╦═════════════════╗"
    echo "║  Upload         ║ Download        ║ Ping            ║"
    echo "╠═════════════════╬═════════════════╬═════════════════╣"
    printf "║ \033[1;33m%-17s\033[0m ║ \033[0;32m%-17s\033[0m ║ %-15s ║\n" "↑ $upload_speed Mbps" "↓ $download_speed Mbps" "$ping ms"
    echo "╚═════════════════╩═════════════════╩═════════════════╝"
    echo "$result_url"
}
display_speed_test
