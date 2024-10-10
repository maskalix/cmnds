#!/bin/bash
# Get the directory where this script is located
SCRIPT_DIR=$(dirname "$0")/../cmnds/
# Path to the configuration file
CONFIG_FILE="$SCRIPT_DIR/variables.conf"

# Function to read the variable value from the config file
read_config() {
    VAR_NAME=$1
    VALUE=$(grep "^${VAR_NAME}=" "$CONFIG_FILE" | cut -d '=' -f 2-)

    if [ -n "$VALUE" ]; then
        echo "$VALUE"
    else
        echo "Variable $VAR_NAME not found in $CONFIG_FILE" >&2
    fi
}

# Function to write/update a variable in the config file
write_config() {
    VAR_NAME=$1
    NEW_VALUE=$2
    
    if grep -q "^${VAR_NAME}=" "$CONFIG_FILE"; then
        sed -i "s/^${VAR_NAME}=.*/${VAR_NAME}=${NEW_VALUE}/" "$CONFIG_FILE"
    else
        echo "${VAR_NAME}=${NEW_VALUE}" >> "$CONFIG_FILE"
    fi
}

# Usage examples:
# Uncomment these to test the functions

# Read a variable from the config file
# read_config "VAR1"

# Write a new value to a variable in the config file
# write_config "VAR1" "new_value"

# Then call read_config again to confirm the update
# read_config "VAR1"

# Real example:
#SCRIPT_DIR=$(dirname "$0")
#MANAGE_CONFIG="$SCRIPT_DIR/cmnds-config.sh"
# VAR1=$(bash "$MANAGE_CONFIG" read_config VAR1)
# bash "$MANAGE_CONFIG" write_config "VAR1" "new_value"
