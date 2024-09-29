#!/bin/bash

# Script to check S.M.A.R.T status of disks

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

# Get a list of all disks
disks=$(ls /dev/sd*)

echo "Checking S.M.A.R.T status for the following disks:"
echo "$disks"

# Loop through each disk and check S.M.A.R.T status
for disk in $disks; do
    echo "Checking $disk..."
    smartctl -H $disk

    if [ $? -ne 0 ]; then
        echo "Failed to check S.M.A.R.T status for $disk. It may not support S.M.A.R.T."
    else
        echo "S.M.A.R.T status check complete for $disk."
    fi

    echo "---------------------------"
done

echo "S.M.A.R.T check completed."
