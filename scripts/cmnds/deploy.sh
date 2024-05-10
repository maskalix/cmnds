#!/bin/bash

# Directory containing scripts
SCRIPTS_DIR="/data/scripts/cmnds"

# Directory to store command links
COMMANDS_DIR="/data/scripts/cmnds/commands"

# Function to make all scripts in SCRIPTS_DIR and its subfolders executable
make_scripts_executable() {
    find "$SCRIPTS_DIR" -type f -name "*.sh" -exec chmod +x {} +
}

# Function to display menu and manage selected commands using dialog
manage_commands() {
    make_scripts_executable

    local script_list=()
    local script_name
    local choice
    local enabled_scripts=()
    local selected_scripts=()
    local initial_enabled=()
    local enabled_commands=()  # Store enabled commands
    local disabled_commands=()  # Store disabled commands

    # Get list of scripts in SCRIPTS_DIR and its subfolders
    while IFS= read -r -d '' script_path; do
        script_name=$(basename "$script_path" .sh)
        if [[ -L "$COMMANDS_DIR/$script_name" ]]; then
            initial_enabled+=( "$script_name" )
        fi
        script_list+=( "$script_path" )  # Store the actual path of the script
    done < <(find "$SCRIPTS_DIR" -type f -name "*.sh" -not -path "$COMMANDS_DIR/*" -print0)

    # Prepare script list for dialog
    for script_path in "${script_list[@]}"; do
        script_name=$(basename "$script_path" .sh)
        if [[ -L "$COMMANDS_DIR/$script_name" ]]; then
            enabled_scripts+=( "$script_name" "" on )
            enabled_commands+=( "$script_name" )
        else
            enabled_scripts+=( "$script_name" "" off )
            disabled_commands+=( "$script_name" )
        fi
    done

    # Add options to enable/disable all scripts
    local enable_disable_all=("Enable all" "" off)
    local disable_all=("Disable all" "" off)

    # Show dialog menu
    choice=$(dialog --clear --checklist "Select scripts to enable/disable" 20 40 10 "${enable_disable_all[@]}" "${disable_all[@]}" "${enabled_scripts[@]}" 2>&1 >/dev/tty)

    # Reset terminal color scheme
    tput sgr0

    # Check if dialog was canceled
    if [[ $? -ne 0 ]]; then
        echo "Dialog canceled. No changes were made."
        exit 0
    fi

    # Convert dialog output to array
    IFS=$'\n' read -rd '' -a selected_scripts <<< "$choice"

    # Check if "Enable all" or "Disable all" is selected
    if [[ " ${selected_scripts[@]} " =~ "Enable all" ]]; then
        for script_path in "${script_list[@]}"; do
            script_name=$(basename "$script_path" .sh)
            enable_command "$script_name" "$script_path"
            enabled_commands+=( "$script_name" )
            disabled_commands=("${disabled_commands[@]/$script_name}")
        done
        echo "All commands enabled."
        exit 0
    elif [[ " ${selected_scripts[@]} " =~ "Disable all" ]]; then
        for script_path in "${script_list[@]}"; do
            script_name=$(basename "$script_path" .sh)
            disable_command "$script_name"
            disabled_commands+=( "$script_name" )
            enabled_commands=("${enabled_commands[@]/$script_name}")
        done
        echo "All commands disabled."
        exit 0
    fi

    # Manage selected commands
    for script_path in "${script_list[@]}"; do
        script_name=$(basename "$script_path" .sh)
        if [[ " ${selected_scripts[@]} " =~ " $script_name " ]]; then
            enable_command "$script_name" "$script_path"  # Pass the actual path of the script
            enabled_commands+=( "$script_name" )
            disabled_commands=("${disabled_commands[@]/$script_name}")
        else
            disable_command "$script_name"
            disabled_commands+=( "$script_name" )
            enabled_commands=("${enabled_commands[@]/$script_name}")
        fi
    done

    # Refresh shell's cache
    hash -r

    # Display enabled and disabled commands in a table
    echo "Enabled commands:"
    printf "%-20s\n" "${enabled_commands[@]}"
    echo
    echo "Disabled commands:"
    printf "%-20s\n" "${disabled_commands[@]}"
}

# Function to enable a command
enable_command() {
    local script_name="$1"
    local script_path="$2"  # Fetch the actual path of the script from the argument
    if [[ -f "$script_path" ]]; then
        chmod +x "$script_path"
        ln -s -f "$script_path" "$COMMANDS_DIR/$script_name"
        echo "Enabled command: $script_name"
    else
        echo "$script_name: command not found"
    fi
}

# Function to disable a command
disable_command() {
    local script_name="$1"
    local command_path="$COMMANDS_DIR/$script_name"
    if [[ -L "$command_path" ]]; then
        rm -f "$command_path"
        echo "Disabled command: $script_name"
    else
        echo "$script_name: command not found"
    fi
}

# Check if dialog is installed
if ! command -v dialog &>/dev/null; then
    echo "Error: dialog is not installed. Please install it and try again."
    exit 1
fi

# Run the function to manage commands
manage_commands
