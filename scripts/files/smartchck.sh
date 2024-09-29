#!/bin/bash

# Script to check S.M.A.R.T status of disks and display results with scores

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

# Print header
echo -e "${BOLD}Disk          | Status    | Score${RESET}"
echo "-----------------------------------------"

# Loop through each disk and check S.M.A.R.T status
for disk in $disks; do
    # Get the overall health status
    status_output=$(smartctl -H $disk 2>&1)
    status=$(echo "$status_output" | grep -i "SMART overall-health" | awk '{print $6}')

    # Default value to 'UNKNOWN' if status not found
    if [ -z "$status" ]; then
        status="UNKNOWN"
    fi

    # Initialize score and max score
    score=100
    max_score=100

    # Get specific SMART attributes for scoring
    reallocated=$(smartctl -A $disk | grep 'Reallocated_Sector_Ct' | awk '{print $10}')
    pending=$(smartctl -A $disk | grep 'Current_Pending_Sector' | awk '{print $10}')
    hours=$(smartctl -A $disk | grep 'Power_On_Hours' | awk '{print $10}')

    # Calculate score based on S.M.A.R.T attributes
    if [ -n "$reallocated" ]; then
        score=$((score - reallocated / 10))
    fi

    if [ -n "$pending" ]; then
        score=$((score - pending * 5))
    fi

    if [ -n "$hours" ]; then
        score=$((score + hours / 100))
    fi

    # Ensure score does not exceed 100 and does not drop below 0
    if [ "$score" -gt 100 ]; then
        score=100
    elif [ "$score" -lt 0 ]; then
        score=0
    fi

    # Print the health status and score
    if [[ "$status" == "PASSED" ]]; then
        printf "%-15s | ${GREEN}%-10s${RESET} | %d/%d\n" "$disk" "$status" "$score" "$max_score"
    elif [[ "$status" == "FAILED" ]]; then
        printf "%-15s | ${RED}%-10s${RESET} | %d/%d\n" "$disk" "$status" "$score" "$max_score"
    else
        printf "%-15s | ${YELLOW}%-10s${RESET} | %d/%d\n" "$disk" "$status" "$score" "$max_score"
    fi
done

echo "-----------------------------------------"
echo "S.M.A.R.T check completed."
