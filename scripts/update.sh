#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to perform the upgrade
perform_upgrade() {
  echo -e "${BLUE}Upgrading packages...${NC}"
  apt upgrade -y

  # Check if docker-ce is in the list of upgradable packages
  if echo "$upgradable" | grep -q "docker-ce"; then
    echo -e "${GREEN}docker-ce is upgradable. Running docker-recover.sh...${NC}"
    if [ -f /data/scripts/docker-recover.sh ]; then
      bash /data/scripts/docker-recover.sh
    else
      echo -e "${RED}docker-recover.sh script not found in /data/scripts/${NC}"
    fi
  else
    echo -e "${YELLOW}docker-ce is not upgradable.${NC}"
  fi

  echo -e "${GREEN}System update completed.${NC}"
}

# Update package list silently
echo -e "${BLUE}Updating package list...${NC}"
apt update -qq

# List upgradable packages
echo -e "${BLUE}Listing upgradable packages...${NC}"
upgradable=$(apt list --upgradable)

# Display upgradable packages
echo "$upgradable"

# Check for -y option
if [[ "$1" == "-y" ]]; then
  perform_upgrade
else
  # Prompt user for confirmation
  read -p "Do you want to continue with the upgrade? (y/N): " confirm

  # Check user response
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    perform_upgrade
  else
    echo -e "${RED}Upgrade canceled by user.${NC}"
  fi
fi
