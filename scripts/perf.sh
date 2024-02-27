#!/bin/bash
# ANSI color code for yellow text
YELLOW='\033[1;33m'
# ANSI color code for light purple text
LIGHT_PURPLE='\033[1;35m'
# ANSI color code for green text
GREEN='\033[0;32m'
# ANSI color code to reset text color
NC='\033[0m'

# Function to display section headers
display_header() {
    echo -e "${YELLOW}$1:${NC}"
}

# Check if iftop is installed
if ! command -v iftop &> /dev/null; then
    echo -e "${GREEN}iftop is not installed. Installing...${NC}"
    # Install iftop using package manager
    # You may need to adjust the package manager based on your system (apt, yum, etc.)
    sudo apt-get update
    sudo apt-get install -y iftop
else
    echo -e "${LIGHT_PURPLE}iftop is already installed.${NC}"
fi

# Check if speedtest is installed
if ! command -v speedtest &> /dev/null; then
    echo -e "${GREEN}Speedtest is not installed. Installing...${NC}"
    # Install Ookla speedtest
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
    sudo apt-get install -y speedtest
else
    echo -e "${LIGHT_PURPLE}Speedtest is already installed.${NC}"
fi

# Display network usage
display_header "Network Usage"
sudo iftop -t -s 2
echo

# Display disk usage
display_header "Disk Usage"
df -h
echo

# Display uptime
display_header "Uptime"
uptime
echo

# Display load average
display_header "Load Average"
top -bn1 | grep load | awk '{printf "%.2f", $(NF-2)}'
echo

# Display RAM usage
display_header "RAM Usage"
free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }'
echo

# Run Ookla speedtest and display result
display_header "Speed Test"
speedtest
echo
