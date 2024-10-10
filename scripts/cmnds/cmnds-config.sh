#!/bin/bash
# Get the directory where this script is located
SCRIPT_DIR=$(dirname "$0")/../cmnds/
# Path to the configuration file
CONFIG_FILE="$SCRIPT_DIR/variables.conf"

# Function to display usage/help message
show_help() {
    echo "Usage:"
    echo "  $0 read_config <VAR_NAME>     - Read the value of VAR_NAME from the config file."
    echo "  $0 write_config <VAR_NAME> <VALUE> - Write or update VAR_NAME with VALUE in the config file."
    echo "  $0 help                       - Show this help message."
}

# Function to read the variable value from the config file
read_config() {
    VAR_NAME=$1
    if [ -z "$VAR_NAME" ]; then
        echo "Error: No variable name provided for reading." >&2
        show_help
        exit 1
    fi

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
    
    if [ -z "$VAR_NAME" ] || [ -z "$NEW_VALUE" ]; then
        echo "Error: Variable name or value missing for writing." >&2
        show_help
        exit 1
    fi
    
    if grep -q "^${VAR_NAME}=" "$CONFIG_FILE"; then
        sed -i "s/^${VAR_NAME}=.*/${VAR_NAME}=${NEW_VALUE}/" "$CONFIG_FILE"
    else
        echo "${VAR_NAME}=${NEW_VALUE}" >> "$CONFIG_FILE"
    fi
}

# Main logic to call the correct function
if [ $# -eq 0 ]; then
    echo "Error: No command provided."
    show_help
    exit 1
fi

COMMAND=$1
shift # Shift arguments to access function parameters

case "$COMMAND" in
    read_config)
        read_config "$@"
        ;;
    write_config)
        write_config "$@"
        ;;
    help)
        show_help
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'"
        show_help
        exit 1
        ;;
esac

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
