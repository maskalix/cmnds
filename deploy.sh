#!/bin/bash

# Directory containing scripts
SCRIPTS_DIR="/data/scripts"

# Directory to store command links
COMMANDS_DIR="/data/scripts/commands"

# Function to make all scripts in SCRIPTS_DIR executable
make_scripts_executable() {
    chmod +x "$SCRIPTS_DIR"/*.sh
}

# Function to display menu and manage selected commands using dialog
manage_commands() {
    make_scripts_executable

    local script_list=("$SCRIPTS_DIR"/*.sh)
    local script_name
    local choice
    local enabled_scripts=()
    local selected_scripts=()
    local initial_enabled=()

    # Check initial state of enabled commands
    for script_path in "${script_list[@]}"; do
        script_name=$(basename "$script_path" .sh)
        if [[ -L "$COMMANDS_DIR/$script_name" ]]; then
            initial_enabled+=( "$script_name" )
        fi
    done

    # Prepare script list for dialog
    for script_path in "${script_list[@]}"; do
        script_name=$(basename "$script_path" .sh)
        if [[ -L "$COMMANDS_DIR/$script_name" ]]; then
            enabled_scripts+=( "$script_name" "" on )
        else
            enabled_scripts+=( "$script_name" "" off )
        fi
    done

    # Show dialog menu
    choice=$(dialog --clear --checklist "Select scripts to enable/disable" 20 40 10 "${enabled_scripts[@]}" 2>&1 >/dev/tty)

    # Check if dialog was canceled
    if [[ $? -ne 0 ]]; then
        echo "Dialog canceled. No changes were made."
        exit 0
    fi

    # Convert dialog output to array
    IFS=$'\n' read -rd '' -a selected_scripts <<< "$choice"

    # Manage selected commands
    for script_name in "${script_list[@]}"; do
        script_name=$(basename "$script_name" .sh)
        if [[ " ${selected_scripts[@]} " =~ " $script_name " ]]; then
            enable_command "$script_name"
        else
            disable_command "$script_name"
        fi
    done

    # Refresh shell's cache
    hash -r
}

# Function to enable a command
enable_command() {
    local script_name="$1"
    local script_path="$SCRIPTS_DIR/$script_name.sh"
    if [[ -f "$script_path" ]]; then
        chmod +x "$script_path"
        ln -s -f "$script_path" "$COMMANDS_DIR/$script_name"
        echo "Enabled command: $script_name"
    else
        echo "Script not found: $script_name"
    fi
}

# Function to disable a command
disable_command() {
    local script_name="$1"
    local command_path="$COMMANDS_DIR/$script_name"
    if [[ -L "$command_path" ]]; then
        rm -f "$command_path"
        echo "Disabled command: $script_name"
    fi
}

# Check if dialog is installed
if ! command -v dialog &>/dev/null; then
    echo "Error: dialog is not installed. Please install it and try again."
    exit 1
fi

# Run the function to manage commands
manage_commands
