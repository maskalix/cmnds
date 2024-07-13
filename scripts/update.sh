#!/bin/bash

# Function to perform the upgrade
perform_upgrade() {
  echo "Upgrading packages..."
  apt upgrade -y

  # Check if docker-ce is in the list of upgradable packages
  if echo "$upgradable" | grep -q "docker-ce"; then
    echo "docker-ce is upgradable. Running docker-recover.sh..."
    if [ -f /data/scripts/docker-recover.sh ]; then
      bash /data/scripts/docker-recover.sh
    else
      echo "docker-recover.sh script not found in /data/scripts/"
    fi
  else
    echo "docker-ce is not upgradable."
  fi

  echo "System update completed."
}

# Update package list
echo "Updating package list..."
apt update

# List upgradable packages
echo "Listing upgradable packages..."
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
    echo "Upgrade canceled by user."
  fi
fi
