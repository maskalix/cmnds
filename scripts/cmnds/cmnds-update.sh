#!/bin/bash
# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
GRAY='\033[1;33m'
# Reset color
NC='\033[0m'

# Function to display section headers
display_header() {
    echo -e "${GRAY}$1${NC}"
}

echo
echo -e "${GREEN}   ________  ____   ______  _____\n  / ____/  |/  / | / / __ \/ ___/\n / /   / /|_/ /  |/ / / / /\__ \\n/ /___/ /  / / /|  / /_/ /___/ /\n\____/_/  /_/_/ |_/_____//____/${NC}"
echo -e "${GREEN}CMNDs update tool${NC}"
echo -e "${GREEN}>> created by Martin Skalicky"
echo -e ">> GitHub → @maskalix\n${NC}"

# Check if /cmnds-temp directory exists
if [ -d "/cmnds-temp" ]; then
    echo "${YELLOW}Removing existing /cmnds-temp directory...${NC}"
    rm -rf /cmnds-temp
fi

# Check if /cmnds-temp directory exists or create it
if [ ! -d "/cmnds-temp" ]; then
    echo "${YELLOW}Creating /cmnds-temp directory...${NC}"
    mkdir /cmnds-temp
fi

# Change to /cmnds-temp directory
cd /cmnds-temp || exit 1

# Download and execute install script
display_header "${YELLOW}Downloading and executing install script${NC}"
wget --no-cache -q https://raw.githubusercontent.com/maskalix/cmnds/main/install.sh && chmod +x install.sh && ./install.sh

# Remove /cmnds-temp directory
display_header "${YELLOW}Installer cleaning up${NC}"
cd .. && rm -rf /cmnds-temp
