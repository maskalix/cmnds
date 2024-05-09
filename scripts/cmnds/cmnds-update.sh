#!/bin/bash
# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
GRAY='\033[1;33m'
# Reset color
NC='\033[0m'

# Function to display section headers
display_header() {
    echo -e "${GRAY}$1:${NC}"
}

# Check if /cmnds-temp directory exists
if [ -d "/cmnds-temp" ]; then
    echo "${YELLOW}Removing existing /cmnds-temp directory...${NC}"
    rm -rf /cmnds-temp
fi

# Create /cmnds-temp directory
mkdir /cmnds-temp
cd /cmnds-temp

# Download and execute install script
display_header "${YELLOW}Downloading and executing install script${NC}"
wget --no-cache -q https://raw.githubusercontent.com/maskalix/cmnds/main/install.sh && chmod +x install.sh && ./install.sh

# Remove /cmnds-temp directory
display_header "${GREEN}Downloaded!${NC}"
display_header "${YELLOW}Cleaning up${NC}"
rm -rf /cmnds-temp
