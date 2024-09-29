#!/bin/bash

# Script to check S.M.A.R.T status of disks and display attributes

# Define colors for output
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"
BOLD="\e[1m"

# Function to install smartmontools
install_smartmontools() {
    if command -v apt &> /dev/null; then
        echo "Detected APT package manager. Installing smartmontools..."
        sudo apt update
        sudo apt install -y smartmontools
    elif command -v yum &> /dev/null; then
        echo "Detected YUM package manager. Installing smartmontools..."
        sudo yum install -y smartmontools
    elif command -v dnf &> /dev/null; then
        echo "Detected DNF package manager. Installing smartmontools..."
        sudo dnf install -y smartmontools
    else
        echo "No compatible package manager found. Please install smartmontools manually."
        exit 1
    fi
}

# Check if smartctl is installed
if ! command -v smartctl &> /dev/null; then
    echo "smartctl could not be found."
    install_smartmontools
fi

# Get a list of all disks and partitions
disks=$(ls /dev/sd*)

# Print header for overall health status
echo -e "${BOLD}Disk          | Status${RESET}"
echo "-------------------------"

# Loop through each disk and check S.M.A.R.T status
for disk in $disks; do
    # Get the overall health status
    status_output=$(smartctl -H $disk 2>&1)
    status=$(echo "$status_output" | grep -i "SMART overall-health" | awk '{print $6}')

    # Check if status is found, else default to 'Unknown'
    if [ -z "$status" ]; then
        status="UNKNOWN"
    fi

    # Print the health status
    if [[ "$status" == "PASSED" ]]; then
        printf "%-15s | ${GREEN}%-10s${RESET}\n" "$disk" "$status"
    elif [[ "$status" == "FAILED" ]]; then
        printf "%-15s | ${RED}%-10s${RESET}\n" "$disk" "$status"
    else
        printf "%-15s | ${YELLOW}%-10s${RESET}\n" "$disk" "$status"
    fi

    # Print SMART attributes
    echo "SMART Attributes for $disk:"
    echo -e "${BOLD}ID#  ATTRIBUTE_NAME          FLAG     VALUE WORST THRESH TYPE      UPDATED  WHEN_FAILED RAW_VALUE${RESET}"
    echo "---------------------------------------------------------------"
    smartctl -A $disk | grep -E '^[[:space:]]*[0-9]+' | while read -r line; do
        # Extract the attribute and its details
        attribute_name=$(echo "$line" | awk '{print $2}')
        if [[ "$line" == *"Pre-fail"* ]]; then
            printf "${YELLOW}%s${RESET}\n" "$line"
        elif [[ "$line" == *"Old_age"* ]]; then
            printf "${RESET}%s${RESET}\n" "$line"
        fi
    done
    echo "---------------------------------------------------------------"
done

echo "S.M.A.R.T check completed."
