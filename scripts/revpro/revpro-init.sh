#!/bin/bash

# Define default folder structure
SCRIPT_DIR=$(dirname "$0")
MANAGE_CONFIG="$SCRIPT_DIR/cmnds-config"
MAIN_FOLDER=$(bash "$MANAGE_CONFIG" read_config REVPRO) # Change this to your desired folder name
CONF_DIR="$MAIN_FOLDER/conf"
MANCONF_DIR="$MAIN_FOLDER/manconf"
MISC_DIR="$MAIN_FOLDER/misc"

# Path to the template files (assuming it's one level up from the script's location)
TEMPLATE_PATH="$SCRIPT_DIR/../revpro/template"

# Help function
help_function() {
    echo "Usage: revpro-init.sh [command]"
    echo ""
    echo "Commands:"
    echo "  open   Opens the configuration file located in $MAIN_FOLDER/site-configs.conf."
    echo "  setup  Sets up/recreates (run only once! or if clean install) the folder structure with a y/N prompt to delete existing content."
    echo "  help   Displays this help text."
}

# Setup function
setup_function() {
    if [ -d "$MAIN_FOLDER" ]; then
        read -p "The folder $MAIN_FOLDER already exists. Do you want to delete its contents? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            echo "Deleting existing content..."
            rm -rf "$MAIN_FOLDER"
        else
            echo "Exiting setup without making changes."
            exit 1
        fi
    fi

    # Create the folder structure
    echo "Creating folder structure..."
    mkdir -p "$CONF_DIR"
    mkdir -p "$MANCONF_DIR"
    mkdir -p "$MISC_DIR"
    echo "Folder structure created successfully in $MAIN_FOLDER."

    # Copy template files
    if [ -d "$TEMPLATE_PATH" ]; then
        echo "Copying template files..."
        cp "$TEMPLATE_PATH/site-configs.conf" "$MAIN_FOLDER"  # Copy site-configs.conf to $MAIN_FOLDER
        # Copy other files to $MAIN_FOLDER/misc excluding site-configs.conf
        find "$TEMPLATE_PATH" -maxdepth 1 -type f ! -name "site-configs.conf" -exec cp {} "$MISC_DIR" \;
        echo "Template files copied successfully."
    else
        echo "Template directory not found at $TEMPLATE_PATH. Please check the path."
    fi
}

# Open config file function
open_function() {
    CONFIG_FILE="$MAIN_FOLDER/site-configs.conf"
    if [ -f "$CONFIG_FILE" ]; then
        echo "Opening configuration file..."
        # You can replace this line with your preferred editor command (e.g., nano, vim)
        nano "$CONFIG_FILE"
    else
        echo "Config file not found. Run 'setup' first to create the folder structure."
    fi
}

# Main logic to parse arguments
if [ $# -eq 0 ]; then
    echo "No command provided. Use 'help' for usage information."
    exit 1
fi

case "$1" in
    open)
        open_function
        ;;
    setup)
        setup_function
        ;;
    help)
        help_function
        ;;
    *)
        echo "Invalid command. Use 'help' for usage information."
        exit 1
        ;;
esac
