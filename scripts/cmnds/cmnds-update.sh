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
echo -e "${GREEN}   ________  ____   ______  _____\n  / ____/  |/  / | / / __ \/ ___/\n / /   / /|_/ /  |/ / / / /\__ \ \n/ /___/ /  / / /|  / /_/ /___/ /\n\____/_/  /_/_/ |_/_____//____/${NC}"
echo -e "${GREEN}CMNDs update tool${NC}"
echo -e "${GREEN}>> created by Martin Skalicky"
echo -e ">> GitHub → @maskalix\n${NC}"

# Temporary directory
temp_dir="$temp_dir"

# Create $temp_dir directory if it doesn't exist
if [ -d "$temp_dir" ]; then
    echo -e "${YELLOW}Removing existing $temp_dir directory...${NC}"
    rm -rf "$temp_dir" || { echo "Failed to remove $temp_dir directory."; exit 1; }
    echo -e "${YELLOW}Creating $temp_dir directory...${NC}"
    mkdir "$temp_dir" || { echo "Failed to create $temp_dir directory."; exit 1; }
else
    echo -e "${YELLOW}Creating $temp_dir directory...${NC}"
    mkdir "$temp_dir" || { echo "Failed to create $temp_dir directory."; exit 1; }
fi

# Download and execute install script
display_header "${YELLOW}Downloading and executing install script${NC}"
wget --no-cache -q https://raw.githubusercontent.com/maskalix/cmnds/main/install.sh -P $temp_dir && chmod +x $temp_dir/install.sh && $temp_dir/install.sh && rm $temp_dir/install.sh

# Move back to parent directory
cd - >/dev/null || { echo "Failed to change to parent directory."; exit 1; }

# Remove $temp_dir directory
display_header "${YELLOW}Installer cleaning up${NC}"
rm -rf "$temp_dir" || echo "Failed to remove $temp_dir directory."
