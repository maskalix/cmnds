#!/bin/bash

# Function to clone the project from GitHub
clone_project() {
    echo "Cloning project from GitHub into $SCRIPTS_DIR..."
    git clone https://github.com/maskalix/cmnds/tree/main/scripts%20 "$SCRIPTS_DIR"
    echo "Project cloned successfully."
}

# Function to initialize the project
initialize_project() {
    # Update deploy.sh with customized directories
    sed -i "s|SCRIPTS_DIR=.*|SCRIPTS_DIR=\"$SCRIPTS_DIR\"|g" "$SCRIPTS_DIR/deploy.sh"
    sed -i "s|COMMANDS_DIR=.*|COMMANDS_DIR=\"$SCRIPTS_DIR/commands\"|g" "$SCRIPTS_DIR/deploy.sh"

    echo "Project initialized successfully."
}

# Function to prompt user for SCRIPTS_DIR
prompt_scripts_dir() {
    read -rp "Enter preferred directory for scripts (default: /data/scripts): " SCRIPTS_DIR
    SCRIPTS_DIR=${SCRIPTS_DIR:-"/data/scripts"}
}

# Main function to execute installation process
install_project() {
    prompt_scripts_dir
    initialize_project
    clone_project

    echo "Installation completed successfully."
}

# Run installation process
install_project
